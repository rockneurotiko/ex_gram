# Configure multiple bots

In this way we will explore different ways to configure multiple bots in the same application.

In this guide, the elixir application is called `my_bot` and the bot's modules will be `MyBot.Bot1`, `MyBot.Bot2`, ...

## Manually

The simpler and easiest way to start different bots, is to setup in a specific configuration value the bot's configuration:

``` elixir
config :my_bot,
  bots: [
    bot_name_1: [method: :polling, token: "TOKEN_BOT_1"],
    bot_name_2: [method: :polling, token: "TOKEN_BOT_2"]
  ]
```

NOTE: I recommend using the same name here than the one you use in your bots when doing `use ExGram.Bot, name: :bot_name_1`

And now in your `application.ex`, manually configure the childs:

``` elixir
  def start(_type, _args) do
    bots = Application.get_env(:my_bot, :bots)

    bot_config_1 = bots[:bot_name_1]
    bot_config_2 = bots[:bot_name_2]

    children = [
      ExGram,
      {MyBot.Bot1, bot_config_1},
      {MyBot.Bot2, bot_config_2}
    ]

    opts = [strategy: :one_for_one, name: MyBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

## With a Dynamic Supervisor

If you plan to have many bots, that you maybe want to be able to start/stop as you want, or to add/delete new bots easily, using a DynamicSupervisor will help you with it.

We can keep the same configuration style, just change it to have the bot's module:

``` elixir
config :my_bot,
  bots: [
    bot_name_1: [bot: MyBot.Bot1, method: :polling, token: "TOKEN_BOT_1"],
    bot_name_2: [bot: MyBot.Bot2, method: :polling, token: "TOKEN_BOT_2"]
  ]
```

Now we will create a bot's dynamic supervisor:

- `lib/my_bot/bot_supervisor.ex`

``` elixir
defmodule MyBot.BotSupervisor do
  use DynamicSupervisor

  @spec start_link(any()) :: Supervisor.on_start() | :ignore
  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_bots() do
    bots = Application.get_env(:my_bot, :bots)

    bots
    |> Enum.with_index()
    |> Enum.map(fn {{bot_name, bot}, index} ->
      %{
        id: index,
        token: Keyword.fetch!(bot, :token),
        method: Keyword.fetch!(bot, :method),
        bot_name: bot_name,
        extra_info: Keyword.get(bot, :extra_info, %{}),
        bot: Keyword.fetch!(bot, :bot)
      }
    end)
    |> Enum.each(&start_bot/1)
  end

  def start_bot(bot) do
    name = String.to_atom("bot_#{bot.bot_name}_#{bot.id}")

    bot_options = [
      token: bot.token,
      method: bot.method,
      name: name,
      id: name,
      bot_name: bot.bot_name,
      extra_info: bot.extra_info
    ]

    child_spec = {bot[:bot], bot_options}

    {:ok, _} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
```


> #### Note {: .info }
> NOTE: This sets the bot's name explicit (`bot_name: bot.bot_name`), this is done in order to allow to use the same bot module with different tokens.
> But it also implies that the name in the configuration is the one that will be used, and not the one setup in `use ExGram.Bot, name: <name>`, it only matters if you make direct calls to ExGram like `ExGram.send_message/3` with `bot: :bot_name`, if you don't need to release different bots with the same bot's module, I recommend deleting that line.

## Using `context.name` for Direct API Calls

When running multiple bots, it's crucial to understand how to identify which bot received an update. This is especially important when using the low-level API directly instead of the DSL.

### The DSL Handles This Automatically

The ExGram DSL (functions like `answer`, `edit`, `delete`) automatically uses `context.name` to identify the correct bot:

```elixir
def handle({:command, "start", _}, context) do
  # This automatically uses the correct bot
  answer(context, "Hello!")
end
```

No additional configuration needed - the DSL knows which bot to use!

### Manual API Calls Require `bot:` Option

When making direct ExGram method calls (outside the DSL), you **must** explicitly specify which bot to use. The `context.name` field contains the bot's name:

```elixir
def handle({:command, "notify_admin", _}, context) do
  admin_chat_id = get_admin_id()
  user = extract_user(context)

  # CORRECT: Use context.name to identify the bot
  ExGram.send_message(
    admin_chat_id,
    "User #{user.id} triggered notify_admin",
    bot: context.name  # This is crucial!
  )

  answer(context, "Admin has been notified")
end
```

> #### Pro tip {: .tip}
> Never hardcode the bot's name (`@name`) or use `MyBot.name()`, always use the `context.name` and pass it 
> around if you need it, like that you will always do API calls with the correct bot

### Why This Matters

Without specifying `bot: context.name`, ExGram will use the default token from config, which might be the wrong bot:

```elixir
# ❌ WRONG: May use wrong bot's token
ExGram.send_message(admin_chat_id, "Message")

# ✅ CORRECT: Uses the bot that received the update
ExGram.send_message(admin_chat_id, "Message", bot: context.name)
```

### Example: Background Task with Multiple Bots

If you need to send messages from a background task or GenServer, store the bot name and use it:

```elixir
defmodule MyApp.NotificationWorker do
  use GenServer

  def start_link(bot_name) do
    GenServer.start_link(__MODULE__, bot_name, name: __MODULE__)
  end

  def init(bot_name) do
    {:ok, %{bot_name: bot_name}}
  end

  def handle_info(:send_notification, state) do
    # Use the stored bot name
    ExGram.send_message(
      chat_id,
      "Scheduled notification",
      bot: state.bot_name
    )

    {:noreply, state}
  end
end
```

### Summary

- **DSL functions** (`answer`, `edit`, etc.) → Automatically use `context.name`
- **Direct API calls** (`ExGram.send_message`, etc.) → Must specify `bot: context.name`
- **Background tasks** → Store and reuse the bot name

See the [Low-Level API](low-level-api.md) guide for more information on direct API calls.


And finally, we just need to change our `application.ex` to start the supervisor and the bots:

- `lib/my_bot/application.ex`
``` elixir
  @impl true
  def start(_type, _args) do
    children = [
      ExGram,
      MyBot.BotSupervisor,
      {Task, &MyBot.BotSupervisor.start_bots/0},
      # ...
    ]

    opts = [strategy: :one_for_one, name: MyBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
```
