# FSM (Finite State Machine)

Many bots need multi-step conversation flows: registration forms, settings wizards, onboarding sequences. You can model these with pattern matching on `context.extra`, but as flows multiply, managing state transitions, validation, and cleanup becomes tedious and error-prone.

[ExGram.FSM](https://hex.pm/packages/ex_gram_fsm) provides structured conversation state management with:

- **Named flows** with explicitly declared states and valid transitions
- **Runtime transition validation** — catch illegal state jumps early
- **Pluggable storage** — ETS for development, bring your own backend for production
- **Key adapters** — scope state per-user, per-chat, or per-topic
- **Router integration** — automatic `:fsm_flow` and `:fsm_state` filter aliases when used with [ExGram.Router](router.md)

> This guide covers the most common usage. For the full API reference and advanced options, see the [ExGram.FSM HexDocs](https://hexdocs.pm/ex_gram_fsm).

## Installation

Add `ex_gram_fsm` to your dependencies:

```elixir
# mix.exs
def deps do
  [
    {:ex_gram, "~> 0.65"},
    {:ex_gram_fsm, "~> 0.1.0"},
    {:jason, ">= 1.0.0"},
    {:req, "~> 0.6"}
  ]
end
```

If you're also using [ExGram.Router](router.md) (recommended), add it too:

```elixir
def deps do
  [
    {:ex_gram, "~> 0.65"},
    {:ex_gram_router, "~> 0.1.0"},
    {:ex_gram_fsm, "~> 0.1.0"},
    {:jason, ">= 1.0.0"},
    {:req, "~> 0.6"}
  ]
end
```

## Defining Flows

Each conversation flow is a module that declares its states and allowed transitions:

```elixir
defmodule MyBot.RegistrationFlow do
  use ExGram.FSM.Flow, name: :registration

  defstates do
    state :get_name,  to: [:get_email]
    state :get_email, to: [:done]
    state :done,      to: []
  end

  def default_state, do: :get_name
end
```

- **`name:`** — Identifies this flow (used in `start_flow/2` and filters)
- **`defstates`** — Declares valid states and where each can transition to
- **`default_state/0`** — The initial state when the flow starts

The transition graph is validated at compile time and enforced at runtime. If you try `transition(context, :done)` from `:get_name`, the configured policy kicks in (raise, log, or ignore).

## Flow Lifecycle

A flow goes through four stages:

1. **Start** — `start_flow(context, :registration)` activates the flow, sets the default state, and clears any previous data.
2. **Transition** — `transition(context, :get_email)` moves to the next state. The transition is validated against the flow's declared graph.
3. **Accumulate** — `update_data(context, %{name: name})` merges data into the flow's persistent data map. Collect form fields step by step.
4. **End** — `clear_flow(context)` resets everything: no active flow, no state, no data.

## Basic Example (Without Router)

You can use ExGram.FSM with plain `handle/2` pattern matching:

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true
  use ExGram.FSM,
    storage: ExGram.FSM.Storage.ETS,
    flows: [MyBot.RegistrationFlow]

  command("register", description: "Start registration")

  def handle({:command, :register, _}, context) do
    context
    |> start_flow(:registration)
    |> answer("What's your name?")
  end

  def handle(
        {:text, name, _},
        %{extra: %{fsm: %ExGram.FSM.State{flow: :registration, state: :get_name}}} = context
      ) do
    context
    |> update_data(%{name: name})
    |> transition(:get_email)
    |> answer("Got it, #{name}! What's your email?")
  end

  def handle(
        {:text, email, _},
        %{extra: %{fsm: %ExGram.FSM.State{flow: :registration, state: :get_email}}} = context
      ) do
    %{name: name} = get_data(context)

    context
    |> update_data(%{email: email})
    |> clear_flow()
    |> answer("Done! Welcome, #{name} (#{email}).")
  end

  def handle(_, context), do: context
end
```

This works fine, but the pattern matching on `context.extra.fsm` is verbose. With [ExGram.Router](router.md), you get dedicated filter aliases.

## With ExGram.Router (Recommended)

When `use ExGram.Router` is present in the same module, `use ExGram.FSM` automatically registers three filter aliases: `:fsm_flow`, `:fsm_state`, and `:fsm_in_flow`.

> **Important:** `use ExGram.Router` must come *before* `use ExGram.FSM`.

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true
  use ExGram.Router
  use ExGram.FSM,
    storage: ExGram.FSM.Storage.ETS,
    flows: [MyBot.RegistrationFlow]

  command("register", description: "Start registration")

  scope do
    filter :command, :register
    handle &MyBot.Handlers.start_registration/1
  end

  scope do
    filter :fsm_flow, :registration

    scope do
      filter :fsm_state, :get_name
      filter :text
      handle &MyBot.Handlers.got_name/2
    end

    scope do
      filter :fsm_state, :get_email
      filter :text
      handle &MyBot.Handlers.got_email/2
    end
  end

  scope do
    handle &MyBot.Handlers.fallback/1
  end
end
```

```elixir
defmodule MyBot.Handlers do
  import ExGram.Dsl

  def start_registration(context) do
    context
    |> start_flow(:registration)
    |> answer("What's your name?")
  end

  def got_name({:text, name, _}, context) do
    context
    |> update_data(%{name: name})
    |> transition(:get_email)
    |> answer("Got it, #{name}! What's your email?")
  end

  def got_email({:text, email, _}, context) do
    %{name: name} = get_data(context)

    context
    |> update_data(%{email: email})
    |> clear_flow()
    |> answer("Registered! Welcome, #{name} (#{email}).")
  end

  def fallback(context), do: context
end
```

The routing structure makes the flow visible at a glance: the outer scope guards on `:fsm_flow`, and each inner scope matches a specific step plus the expected input type.

### FSM Filter Reference

| Filter | Options | Matches when… |
|--------|---------|---------------|
| `:fsm_flow` | atom or `nil` | Active flow matches the given name (or `nil` for no active flow) |
| `:fsm_state` | atom | Current state matches the given atom |
| `:fsm_state` | `{key, value}` | `fsm_data[key] == value` |
| `:fsm_in_flow` | (none) | Any flow is active |

## Helper Functions

`use ExGram.FSM` imports these functions into your bot module (and they're available in handler modules that import from the bot):

| Function | Description |
|----------|-------------|
| `start_flow(context, flow_name)` | Start a flow — sets default state and clears data |
| `transition(context, state)` | Move to the next state (validated) |
| `set_state(context, state)` | Force-set state, bypassing validation |
| `set_state(context, flow, state)` | Force-set flow + state (escape hatch) |
| `get_flow(context)` | Current active flow name, or `nil` |
| `get_state(context)` | Current step within the active flow, or `nil` |
| `get_data(context)` | FSM data map (never `nil`) |
| `update_data(context, map)` | Merge a map into the FSM data |
| `clear_flow(context)` | Reset: no flow, no state, no data |

All helpers take and return `ExGram.Cnt.t()`, so they work seamlessly in pipelines.

### `transition/2` vs `set_state/2`

- **`transition/2`** validates the move against the flow's declared transitions and applies the `on_invalid_transition` policy if it's not allowed. This is the normal path — use it in your handlers.
- **`set_state/2`** and **`set_state/3`** bypass validation entirely. Use them for admin tools, recovery, or testing.

## Transition Policies

Configure what happens when an invalid transition is attempted:

```elixir
use ExGram.FSM,
  storage: ExGram.FSM.Storage.ETS,
  flows: [MyBot.RegistrationFlow],
  on_invalid_transition: :log  # or :raise, :ignore, {Module, :function}
```

| Policy | Behavior |
|--------|----------|
| `:raise` (default) | Raises `ExGram.FSM.TransitionError` |
| `:log` | Logs a warning, returns context unchanged |
| `:ignore` | Silent no-op, returns context unchanged |
| `{Module, :function}` | Calls `Module.function(context, from, to)` for custom handling |

## Storage Backends

The default backend is `ExGram.FSM.Storage.ETS` — in-memory, single-node, and **state is lost on restart**. This is fine for development and simple bots.

For production, implement the `ExGram.FSM.Storage` behaviour:

```elixir
defmodule MyBot.RedisStorage do
  @behaviour ExGram.FSM.Storage

  @impl true
  def init(bot_name, _opts), do: :ok

  @impl true
  def get_state(bot_name, key), do: # read from Redis

  @impl true
  def set_state(bot_name, key, %ExGram.FSM.State{} = state), do: # write

  @impl true
  def get_data(bot_name, key), do: # read data

  @impl true
  def set_data(bot_name, key, data), do: # write data

  @impl true
  def update_data(bot_name, key, new_data), do: # merge and write

  @impl true
  def clear(bot_name, key), do: # delete
end
```

Use it:

```elixir
use ExGram.FSM, storage: MyBot.RedisStorage, flows: [...]
```

Storage is bot-scoped: the `bot_name` argument lets a single backend serve multiple bots without key collisions. The ETS implementation creates one named table per bot.

## Key Adapters

Key adapters control how FSM state is scoped — who shares state with whom:

| Adapter | Key | Use case |
|---------|-----|----------|
| `ExGram.FSM.Key.ChatUser` (default) | `{chat_id, user_id}` | Each user has independent state per chat |
| `ExGram.FSM.Key.User` | `{user_id}` | Same state across all chats (DMs, groups) |
| `ExGram.FSM.Key.Chat` | `{chat_id}` | Shared state for all users in a chat |
| `ExGram.FSM.Key.ChatTopic` | `{chat_id, thread_id}` | Per forum topic, shared |
| `ExGram.FSM.Key.ChatTopicUser` | `{chat_id, thread_id, user_id}` | Per-user per forum topic |

```elixir
# User-scoped: state follows the user everywhere
use ExGram.FSM, key: ExGram.FSM.Key.User, flows: [...]

# Chat-scoped: shared state, e.g. group game sessions
use ExGram.FSM, key: ExGram.FSM.Key.Chat, flows: [...]
```

You can also implement `ExGram.FSM.Key` to define your own scoping strategy.

## Next Steps

- [Router](router.md) - Declarative routing DSL (pairs perfectly with FSM)
- [Middlewares](middlewares.md) - Enrich context before routing and FSM
- [Handling Updates](handling-updates.md) - Understand update types
- [Testing](testing.md) - Test your bot end-to-end
