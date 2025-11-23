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

  @spec start_link(any()) :: Supervisor.on_start_child() | :ignore
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


NOTE: This sets the bot's name in line 40 (`bot_name: bot.bot_name`), this is done in order to allow to use the same bot module with different tokens, but it also implies that the name in the configuration is the one that will be used, and not the one setup in `use ExGram.Bot, name: <name>`, it only matters if you make direct calls to `ExGram` like `ExGram.send_message(..., bot: :bot_name)`, if you don't need to release different bots with the same bot's module, I recommend deleting that line.


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
