# Bot Init Hooks

Bot Init hooks allow you to run custom code during the bot's startup sequence, before it begins processing updates. They are the right place for initialization that depends on the bot's token or identity - fetching external configuration, pre-warming caches, validating credentials, or anything else that must succeed before the bot can function.

## Overview

A Bot Init hook is a module that implements the `ExGram.BotInit` behaviour. The single callback `on_bot_init/1` is called once during startup. Each hook can pass data forward to subsequent hooks and to every handler call via `context.extra`.

Hooks run in this sequence during startup:

1. `ExGram.BotInit.GetMe` (built-in, enabled by default)
2. `ExGram.BotInit.SetupCommands` (built-in, enabled when `setup_commands: true`)
3. Your custom hooks (in declaration order)
4. `init/1` callback on the bot module
5. Bot starts receiving updates

If any hook returns `{:error, reason}`, the bot supervisor shuts down cleanly with reason `{:on_bot_init_failed, module, reason}`.

## Declaring Hooks

Use the `on_bot_init/1-2` macro inside your bot module:

```elixir
defmodule MyApp.Bot do
  use ExGram.Bot, name: :my_bot

  on_bot_init(MyApp.ConfigHook)
  on_bot_init(MyApp.CacheWarmHook, ttl: 300)

  command("start")

  def handle({:command, :start, _}, context) do
    answer(context, "Hello! Config: #{context.extra[:app_config]}")
  end
end
```

## Implementing a Hook

Implement the `ExGram.BotInit` behaviour with a single callback:

```elixir
defmodule MyApp.ConfigHook do
  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    token = opts[:token]
    bot = opts[:bot]
    current_extra = opts[:extra_info]

    case MyApp.Config.fetch(token) do
      {:ok, config} ->
        # Return a map to merge into context.extra for all subsequent hooks and handlers
        {:ok, %{app_config: config}}

      {:error, reason} ->
        # Returning {:error, reason} stops startup and shuts down the bot
        {:error, {:config_fetch_failed, reason}}
    end
  end
end
```

### Callback Return Values

| Return | Effect |
|---|---|
| `:ok` | Hook succeeded; `extra_info` is unchanged |
| `{:ok, map}` | Hook succeeded; `map` is merged into `extra_info` for subsequent hooks and handlers |
| `{:error, reason}` | Hook failed; bot shuts down with `{:on_bot_init_failed, module, reason}` |

### Hook Options

`on_bot_init/1` receives a keyword list with:

| Key | Type | Description |
|---|---|---|
| `:bot` | `atom()` | The bot's registered name |
| `:token` | `String.t()` | The bot's token |
| `:extra_info` | `map()` | Accumulated extra data from previous hooks |
| custom keys | `any()` | Any options passed to `on_bot_init/2` |

## Passing Options to Hooks

Use `on_bot_init/2` to pass custom options to a hook at declaration time:

```elixir
on_bot_init(MyApp.CacheWarmHook, ttl: 300, namespace: "my_bot")
```

The options are merged into the keyword list received by `on_bot_init/1`:

```elixir
defmodule MyApp.CacheWarmHook do
  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    ttl = Keyword.get(opts, :ttl, 60)
    namespace = Keyword.get(opts, :namespace, "default")

    MyApp.Cache.warm(namespace, ttl: ttl)
    :ok
  end
end
```

## Sharing Data Between Hooks

Each hook receives `extra_info` containing all data produced by hooks that ran before it. Return `{:ok, map}` to merge new data in:

```elixir
defmodule MyApp.AuthHook do
  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    bot = opts[:bot]

    case MyApp.Auth.validate_bot(bot) do
      {:ok, permissions} -> {:ok, %{bot_permissions: permissions}}
      {:error, :invalid} -> {:error, :invalid_token}
    end
  end
end

defmodule MyApp.SetupHook do
  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    # Permissions were set by AuthHook, accessible via extra_info
    permissions = opts[:extra_info][:bot_permissions]

    if :admin in permissions do
      {:ok, %{admin_chat_id: MyApp.Config.admin_chat_id()}}
    else
      :ok
    end
  end
end
```

## Accessing Hook Data in Handlers

Data added by hooks is available in every handler call via `context.extra`:

```elixir
defmodule MyApp.Bot do
  use ExGram.Bot, name: :my_bot

  on_bot_init(MyApp.AuthHook)
  on_bot_init(MyApp.SetupHook)

  command("status")

  def handle({:command, :status, _}, context) do
    permissions = context.extra[:bot_permissions]
    answer(context, "Permissions: #{inspect(permissions)}")
  end

  def handle(_, context), do: context
end
```

## Built-in Hooks

ExGram provides two built-in hooks that are automatically injected by the dispatcher at startup.

### `ExGram.BotInit.GetMe`

Calls `ExGram.get_me/1` to fetch the bot's identity from Telegram. Enabled by default (`get_me: true`).

The result, the bot's information in an `ExGram.Model.User` struct, is stored as `state.bot_info` in the dispatcher and becomes available as `context.bot_info` in every handler call.

Disable it when you don't need the bot's identity or want to avoid the startup API call:

```elixir
{MyApp.Bot, [method: :polling, token: token, get_me: false]}
```

### `ExGram.BotInit.SetupCommands`

Registers the bot's declared commands with Telegram via `setMyCommands`. Only runs when `setup_commands: true`:

```elixir
use ExGram.Bot, name: :my_bot, setup_commands: true
# or at startup:
{MyApp.Bot, [method: :polling, token: token, setup_commands: true]}
```

### Execution Order

Built-in hooks always run before custom hooks:

```
GetMe -> SetupCommands (if enabled) -> your custom hooks -> init/1
```

## Error Handling

When a hook returns `{:error, reason}`, the dispatcher:

1. Logs an error: `ExGram: on_bot_init hook MyHook failed for bot :my_bot: reason`
2. Stops the dispatcher with reason `{:shutdown, {:on_bot_init_failed, MyHook, reason}}`

The bot's supervisor propagates this shutdown, which means the whole bot process tree stops. This is intentional - if a required initialization step fails, there is no safe state to operate in.

```elixir
defmodule MyApp.RequiredHook do
  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    case fetch_required_config(opts[:token]) do
      {:ok, config} ->
        {:ok, %{config: config}}

      {:error, reason} ->
        # Bot will not start - logged and supervisor shuts down
        {:error, {:required_config_missing, reason}}
    end
  end
end
```

## Testing Hooks

Hooks participate in the normal test adapter lifecycle. Use `ExGram.Test.stub/2` or `ExGram.Test.expect/2` to control any API calls your hook makes.

By default, `ExGram.Test.start_bot/3` sets `get_me: false` and `setup_commands: false` to avoid unnecessary API calls. Your own hooks declared with `on_bot_init/1-2` always run.

If you want to optionally enable/disable your init hooks, you can stop running them if a specific field exists in the extra_info map, and start your bots with that value.

```elixir
defmodule MyHook do
  @behaviour ExGram.BotInit
  
  @impl ExGram.BotInit
  def on_bot_init(opts) do
    if opts[:extra_info][:my_hook_disable] do
      :ok
    else
      do_init(opts)
    end
  end
end

defmodule MyApp.BotTest do
  use ExUnit.Case, async: true
  use ExGram.Test

  import ExGram.TestHelpers

  setup context do
    {bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot, extra_info: %{__my_hook_disable: true})
    {:ok, bot_name: bot_name}
  end
end
```

To test `get_me: true` or `setup_commands: true` startup hooks, pass them explicitly:

```elixir
ExGram.Test.stub(:get_me, %{id: 1, is_bot: true, username: "my_bot"})
{bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot, get_me: true)
```

## Next Steps

- [Middlewares](middlewares.md) - Add preprocessing logic that runs on every update
- [Testing](testing.md) - Test your bot and its initialization hooks
- [Handling Updates](handling-updates.md) - Learn about the handler patterns
