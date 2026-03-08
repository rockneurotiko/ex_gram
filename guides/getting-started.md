# Getting Started

This guide walks you through creating your first ExGram bot from scratch.

## Prerequisites

Make sure you have:
- Elixir installed (1.15 or later)
- A Telegram Bot Token from [@BotFather](https://t.me/botfather)
- Completed the [Installation](installation.md) guide

## Create a New Project

Create a new Elixir project with supervision tree:

```bash
mix new my_bot --sup
cd my_bot
```

## Install ExGram

Add ExGram to `mix.exs` as shown in the [Installation](installation.md) guide, then:

```bash
mix deps.get
```

## Generate Your Bot

ExGram provides a Mix task to generate a bot module:

```bash
mix bot.new
```

This creates `lib/my_bot/bot.ex` with a basic bot structure:

```elixir
defmodule MyBot.Bot do
  @bot :my_bot

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Here is your help:")
  end
end
```

### Understanding the Generated Bot

- `@bot :my_bot` - Internal name for your bot
- `use ExGram.Bot` - Imports the bot framework
- `setup_commands: true` - Automatically registers commands with Telegram
- `command/1-2` - Declares commands that your bot handles
- `middleware/1` - Adds middleware to the processing pipeline
- `handle/2` - Handles incoming updates

## Configure Your Application

Get your bot token from [@BotFather](https://t.me/botfather) and configure it in `config/config.exs`:

```elixir
import Config

config :ex_gram,
  token: "YOUR_BOT_TOKEN_HERE"
```

**Security Note:** For production, use environment variables instead:

```elixir
config :ex_gram,
  token: System.get_env("BOT_TOKEN")
```

## Add Bot to Supervision Tree

Open `lib/my_bot/application.ex` and add ExGram and your bot to the children list:

```elixir
defmodule MyBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExGram,
      {MyBot.Bot, [method: :polling, token: Application.fetch_env!(:ex_gram, :token)]}
    ]

    opts = [strategy: :one_for_one, name: MyBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Key points:**
- `ExGram` must be started before your bot 
- `method: :polling` - Use polling to receive updates, learn more about how to get updates [in this guide](./polling-and-webhooks.md)
- `token:` - Pass the token explicitly

## Run Your Bot

Start your bot:

```bash
mix run --no-halt
```

Open Telegram and send `/start` to your bot. It should reply with "Hi!"

## Token Configuration Options

### 1. Global Config + Exlicit on bot

```elixir
# config/config.exs
config :ex_gram, token: "TOKEN"

# lib/my_bot/application.ex
{MyBot.Bot, [method: :polling, token: "TOKEN"]}
```

### 2. Explicit Token (Recommended for Multiple Bots)

```elixir
# lib/my_bot/application.ex
token = System.get_env("BOT_TOKEN") || Application.fetch_env!(:ex_gram, :token)
{MyBot.Bot, [method: :polling, token: token]}
```

### 3. Runtime Configuration

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :ex_gram,
    token: System.fetch_env!("BOT_TOKEN")
end
```

## Next Steps

Now that you have a working bot:

- [Handling Updates](handling-updates.md) - Learn about different update types
- [Sending Messages](sending-messages.md) - Explore the DSL for building responses
- [Polling and Webhooks](polling-and-webhooks.md) - Configure how your bot receives updates

## Troubleshooting

### Bot doesn't respond

1. Check that `ExGram` is listed before your bot in the supervision tree
2. Verify your token is correct
3. Check logs for errors: `Logger.configure(level: :debug)`

### "Registry.ExGram not started"

Make sure `ExGram` is in your supervision tree before your bot.
