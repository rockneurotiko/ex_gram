# Router

As your bot grows, the `handle/2` function can become a long chain of pattern-match clauses — commands, callback queries, text handlers, inline queries, all interleaved in a single module. When you add conversation flows or role-based access, the clause count explodes and it becomes hard to see the overall structure at a glance.

[ExGram.Router](https://hex.pm/packages/ex_gram_router) replaces those hand-written clauses with a declarative **scope / filter / handle** DSL. You describe *what* each handler should match, and the router takes care of dispatching. Everything compiles down to a standard `handle/2` function, so the rest of ExGram (middlewares, DSL, testing) works exactly the same.

## Installation

Add `ex_gram_router` to your dependencies:

```elixir
# mix.exs
def deps do
  [
    {:ex_gram, "~> 0.65"},
    {:ex_gram_router, "~> 0.1.0"},
    {:jason, ">= 1.0.0"},
    {:req, "~> 0.5"}
  ]
end
```

Then add `:ex_gram_router` to the formatter deps alongside `:ex_gram`:

```elixir
# .formatter.exs
[
  import_deps: [:ex_gram, :ex_gram_router]
]
```

## From `handle/2` to Scopes

Here's a typical bot using plain `handle/2`:

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true

  command("start", description: "Start the bot")
  command("help",  description: "Show help")

  def handle({:command, :start, _}, ctx), do: answer(ctx, "Welcome!")
  def handle({:command, :help, _}, ctx),  do: answer(ctx, "Here is what I can do…")
  def handle({:text, _, _}, ctx),         do: answer(ctx, "You said something!")
  def handle(_, ctx),                     do: ctx
end
```

The same bot with `ExGram.Router`:

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true
  use ExGram.Router

  command("start", description: "Start the bot")
  command("help",  description: "Show help")

  scope do
    filter :command, :start
    handle &MyBot.Handlers.start/1
  end

  scope do
    filter :command, :help
    handle &MyBot.Handlers.help/1
  end

  scope do
    filter :text
    handle &MyBot.Handlers.echo/1
  end

  # Catch-all fallback
  scope do
    handle &MyBot.Handlers.fallback/1
  end
end
```

```elixir
defmodule MyBot.Handlers do
  import ExGram.Dsl

  def start(ctx), do: answer(ctx, "Welcome!")
  def help(ctx),  do: answer(ctx, "Here is what I can do…")
  def echo(ctx),  do: answer(ctx, "You said something!")
  def fallback(ctx), do: ctx
end
```

Notice that handlers live in their own module. This is optional — you can keep them inline — but separating handlers from routing keeps both sides clean as the bot grows.

### How dispatch works

1. Scopes are tried **top-to-bottom** in declaration order.
2. All filters in a scope must pass (AND logic).
3. The **first matching leaf** wins — its handler runs and dispatch stops.
4. A scope with **no filters** matches everything, so a filter-less scope at the bottom acts as a fallback.

## Built-in Filters

The router ships with filters for the most common update types. Use them by alias name:

```elixir
# Commands
filter :command              # any command
filter :command, :start      # specific command

# Text messages
filter :text                 # any text
filter :text, "hello"        # exact match
filter :text, ~r/^\d+$/      # regex match
filter :text, prefix: "!"    # starts with
filter :text, contains: "hi" # contains substring

# Callback queries
filter :callback_query                    # any callback
filter :callback_query, "confirm"         # exact data
filter :callback_query, ~r/^page_\d+$/   # regex match
filter :callback_query, prefix: "settings:" # prefix match

# Inline queries
filter :inline_query
filter :inline_query, prefix: "@"

# Media & other types
filter :photo
filter :document
filter :location
filter :sticker
filter :voice
filter :video
filter :animation
filter :audio
filter :contact
filter :poll
filter :video_note
filter :message    # any message-type update
filter :regex      # any named regex match
```

Each filter alias maps to a module under `ExGram.Router.Filters.*`. You never need to reference them directly, but you can if you prefer.

## Nested Scopes

Scopes can be nested. A child scope only runs if its parent's filters already passed, so parent filters act as guards for all children:

```elixir
scope do
  filter :callback_query, prefix: "settings:"

  scope do
    filter :callback_query, "settings:language"
    handle &MyBot.Handlers.settings_language/1
  end

  scope do
    filter :callback_query, "settings:timezone"
    handle &MyBot.Handlers.settings_timezone/1
  end
end
```

This is especially useful for callback queries with hierarchical data patterns. Instead of repeating the prefix in every leaf, you filter it once at the parent level.

### Prefix Propagation

For deeply nested callback data, you can use `propagate: true` on a prefix filter. The matched prefix is stripped and child scopes match against the **remainder**:

```elixir
scope do
  filter :callback_query, prefix: "proj:", propagate: true

  scope do
    filter :callback_query, "change"   # matches "proj:change"
    handle &MyBot.Handlers.change_project/1
  end

  scope do
    filter :callback_query, prefix: "settings:", propagate: true

    scope do
      filter :callback_query, "volume"   # matches "proj:settings:volume"
      handle &MyBot.Handlers.volume/1
    end
  end
end
```

Propagation stacks across nesting levels, so you can model arbitrary callback data hierarchies cleanly.

## Custom Filters

When the built-in filters aren't enough, you can implement the `ExGram.Router.Filter` behaviour to encode any runtime predicate - user roles, conversation state, feature flags, and more. See the [Custom Filters section in the ExGram.Router documentation](https://github.com/rockneurotiko/ex_gram_router#custom-filters) for the full guide including examples and alias registration.

## Handler Arities

Handlers can be **1-arity** or **2-arity**:

```elixir
# 1-arity: receives only context
def start(context) do
  answer(context, "Welcome!")
end

# 2-arity: receives (update_info, context)
def echo({:command, _name, %{text: text}}, context) do
  answer(context, text)
end
```

The router detects the arity at compile time. Use 2-arity when you need to extract data from the parsed update tuple directly.

## Inspecting Routes

The router ships with two mix tasks for visualizing your bot's routing configuration:

### `mix ex_gram.router.tree`

Prints the full scope tree with indentation:

```text
$ mix ex_gram.router.tree MyBot

MyBot routing tree:
├── scope
│   ├── filters: [Command(:start)]
│   └── handle: &MyBot.Handlers.start/1
├── scope
│   ├── filters: [Command(:help)]
│   └── handle: &MyBot.Handlers.help/1
└── scope
    ├── filters: [CallbackQuery([prefix: "proj:"]) [propagate]]
    ├── scope
    │   ├── filters: [CallbackQuery("change")]
    │   └── handle: &MyBot.Handlers.change_project/1
    └── scope
        ├── filters: [CallbackQuery("delete")]
        └── handle: &MyBot.Handlers.delete_project/1
```

### `mix ex_gram.router.flat`

Prints one line per handler with the full accumulated filter chain, similar to `mix phx.routes` in Phoenix:

```text
$ mix ex_gram.router.flat MyBot

MyBot handlers:
MyBot.Handlers  start/1          filters: [Command(:start)]
MyBot.Handlers  help/1           filters: [Command(:help)]
MyBot.Handlers  change_project/1 filters: [CallbackQuery([prefix: "proj:"]) [propagate], CallbackQuery("change")]
MyBot.Handlers  delete_project/1 filters: [CallbackQuery([prefix: "proj:"]) [propagate], CallbackQuery("delete")]
MyBot.Handlers  fallback/1       filters: []
```

These are invaluable for debugging routing issues or onboarding new team members.

## Testing

The router generates a standard `handle/2` function, so testing works exactly like any other ExGram bot. Use `ExGram.Adapter.Test`, push updates, and assert on outgoing API calls. No special setup needed.

See the [Testing](testing.md) guide for details.

## Next Steps

- [FSM](fsm.md) - Add finite state machine conversation flows (works great with the router)
- [Middlewares](middlewares.md) - Enrich context with data your filters need
- [Handling Updates](handling-updates.md) - Understand the update tuples that filters match against
- [Cheatsheet](cheatsheet.md) - Quick reference for common patterns
