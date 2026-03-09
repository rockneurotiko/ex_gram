# ExGram

<p align="center"><img src="https://raw.githubusercontent.com/rockneurotiko/ex_gram/refs/heads/master/assets/ex_gram_logo.png" alt="ExGram" height="300px"></p>

[![Hex.pm](https://img.shields.io/hexpm/v/ex_gram.svg)](http://hex.pm/packages/ex_gram)
[![Documentation](https://img.shields.io/badge/documentation-4B275F?logo=elixir)](https://hexdocs.pm/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Build Status](https://github.com/rockneurotiko/ex_gram/actions/workflows/ci.yml/badge.svg)](https://github.com/rockneurotiko/ex_gram/actions/workflows/ci.yml)

**ExGram** is a powerful Elixir library for building Telegram Bots. Use the low-level API for fine-grained control, or leverage the opinionated framework for rapid bot development.

## Features

- **Automatic API Generation** - Always up-to-date with the latest [Telegram Bot API](https://core.telegram.org/bots/api)
- **Flexible DSL** - Build responses elegantly with the context-based DSL
- **Polling & Webhooks** - Choose the update method that fits your needs
- **Easy discovery of the API** - Complete typespecs and documentation for all methods and models
- **Middleware System** - Add authentication, logging, and custom processing
- **Message Entities Builder** - Easily format messages without Markdown/HTML escaping
- **Multiple Bots** - Run multiple different bots, or instances of the same bot in a single application
- **Production Ready** - Battle-tested in real-world applications

## Quick Start

### Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:ex_gram, "~> 0.58"},
    {:jason, "~> 1.4"},
    {:req, "~> 0.5"}  # HTTP adapter
  ]
end
```

Configure the adapter:

```elixir
# config/config.exs
config :ex_gram, adapter: ExGram.Adapter.Req
```

### Your First Bot

Generate a bot module:

```bash
mix bot.new
```

Add to your supervision tree:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  children = [
    ExGram,
    {MyApp.Bot, [method: :polling, token: "YOUR_BOT_TOKEN"]}
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Implement handlers:

```elixir
defmodule MyApp.Bot do
  use ExGram.Bot, name: :my_bot, setup_commands: true

  import ExGram.Dsl.Keyboard

  command("start")
  command("help", description: "Show help")
  
  middleware(ExGram.Middleware.IgnoreUsername)  

  def handle({:command, :start, _}, context) do
    answer(context, "Welcome! I'm your bot.")
  end

  def handle({:command, :help, _}, context) do
    message = """
    Available commands:
    /start - Start the bot
    /help - Show this help
    """

    keyboard = 
      keyboard :inline do
        row do
          button "Test button", callback_data: "button"
        end
      end

    answer(context, message, reply_markup: keyboard)
  end

  def handle({:callback_query, %{data: "button"}}, context) do
    context
    |> answer_callback("Button clicked!")
    |> edit(:inline, "You clicked the button!")
  end
end
```

Run your bot:

```bash
mix run --no-halt
```

## DSL Functions

The ExGram DSL builds actions on the context that execute after your handler returns.

### Sending Messages

```elixir
context 
|> answer("Hello!")
|> answer_document({:file, "/path/to/file.pdf"})
```

### Inline Keyboards

- With the DSL

```elixir
import ExGram.Dsl.Keyboard

markup = 
  keyboard :inline do
    row do
      button "Button text", callback_data: "button"
    end
  end
  
answer(context, "Choose:", reply_markup: markup)
```

- With a helper method

```elixir
markup = create_inline_keyboard([
  [%{text: "Button", callback_data: "button"}]
])
answer(context, "Choose:", reply_markup: markup)
```

### Editing & Deleting

```elixir
edit(context, "Updated message")
edit_markup(context, new_keyboard)
delete(context)
```

### Callback Queries & Inline Queries

```elixir
answer_callback(context, "Processing...")
answer_inline_query(context, results)
```

### Use steps results

```elixir
context
|> answer("Important message!")
|> on_result(fn 
  {:ok, message}, name ->
    ExGram.pin_chat_message(message.chat.id, message.message_id, bot: name)
    
  error, _name ->
    error
end)
```

### Extracting Information

```elixir
extract_id(context)           # Chat ID
extract_user(context)         # User
extract_message_id(context)   # Message ID
extract_update_type(context)  # Update type
extract_message_type(context) # Message type
```

### Low-Level API

Use ExGram as a library without the framework:

```elixir
# Configure globally
config :ex_gram, token: "YOUR_TOKEN"

ExGram.send_photo(chat_id, {:file, "photo.jpg"})
ExGram.get_me()

# Or you can pass the token directly
ExGram.send_message(chat_id, "Hello!", token: "YOUR_TOKEN")
```

All methods return `{:ok, result} | {:error, ExGram.Error.t()}` and have bang variants:

```elixir
{:ok, message} = ExGram.send_message(chat_id, "Hello")
message = ExGram.send_message!(chat_id, "Hello")  # Raises on error
```


See the [Sending Messages](guides/sending-messages.md) guide for a complete reference or the [Cheatsheet](guides/cheatsheet.md) for a quick overview.

## Documentation

### Getting Started

- [Installation](guides/installation.md) - HTTP adapters, JSON engines, configuration
- [Getting Started](guides/getting-started.md) - Create your first bot

### Building Bots

- [Handling Updates](guides/handling-updates.md) - Process commands, messages, and other updates
- [Sending Messages](guides/sending-messages.md) - DSL philosophy and response building
- [Define commands](guides/commands.md) - Clearly define you bot's commands, with options for different scopes and languages
- [Message Entities](guides/message-entities.md) - Format messages without dealing with MarkdownV2 or HTML
- [Middlewares](guides/middlewares.md) - Add preprocessing logic

### Advanced

- [Polling and Webhooks](guides/polling-and-webhooks.md) - Configure update methods
- [Low-Level API](guides/low-level-api.md) - Direct API calls for complex scenarios
- [Multiple Bots](guides/multiple-bots.md) - Run multiple bots in one application
- [Testing](guides/testing.md) - Test your bots

### Deployment

- [Fly.io](guides/flyio.md) - Deploy your bot to production

### Reference

- [Cheatsheet](guides/cheatsheet.md) - Quick reference for common patterns
- [HexDocs](https://hexdocs.pm/ex_gram) - Complete API documentation

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Beer-Ware License. See [LICENSE](LICENSE) for details.

## Links

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [HexDocs](https://hexdocs.pm/ex_gram)
- [Hex Package](https://hex.pm/packages/ex_gram)
- [telegram_api_json](https://github.com/rockneurotiko/telegram_api_json) - API JSON generator
