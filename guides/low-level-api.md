# Low-Level API

The low-level API provides direct access to all Telegram Bot API methods without the DSL framework. This is useful for:

- **Complex bots** with background tasks or scheduled jobs
- **Fine-grained control** over requests and responses
- **Library usage** without the bot framework
- **Direct integration** with other systems

## How It Works

ExGram's low-level API is **automatically generated** from an up-to-date JSON description of the Telegram Bot API using the [telegram_api_json](https://github.com/rockneurotiko/telegram_api_json) project.

### The Generation Process

1. The `telegram_api_json` project scrapes the [Telegram Bot API documentation](https://core.telegram.org/bots/api)
2. It produces a standardized JSON file with all methods, parameters, and models
3. A Python script (`extractor.py`) reads this JSON and generates Elixir code
4. Macros in `lib/ex_gram/macros.ex` create methods and models with proper typespecs

**Result:** Every method has correct type specs and documentation, making the API a pleasure to use!

## Models

All models are in the `ExGram.Model` module and match the [Telegram Bot API documentation](https://core.telegram.org/bots/api) one-to-one.

### Using Models

```elixir
alias ExGram.Model.{User, Message, Chat, Update}

# Models have correct typespecs
@spec get_user_name(User.t()) :: String.t()
def get_user_name(%User{first_name: first, last_name: last}) do
  "#{first} #{last || ""}"
end
```

### Inspecting Model Types

In IEx, you can view model types:

```elixir
iex> t ExGram.Model.User
@type t() :: %ExGram.Model.User{
  first_name: String.t(),
  id: integer(),
  is_bot: boolean(),
  language_code: String.t(),
  last_name: String.t(),
  username: String.t()
}
```

Or use the built-in introspection:

```bash
mix run --eval 'IEx.Introspection.t({ExGram.Model, :User})'
```

## Methods

All methods are in the `ExGram` module and follow these conventions:

### Naming Convention

Telegram's `camelCase` → Elixir's `snake_case`

- `sendMessage` → `send_message`
- `getUpdates` → `get_updates`
- `answerCallbackQuery` → `answer_callback_query`

### Method Signatures

**Mandatory parameters** → Function arguments (in order from docs)
**Optional parameters** → Keyword list in last argument

```elixir
# sendMessage has 2 mandatory params: chat_id, text
ExGram.send_message(chat_id, text)
ExGram.send_message(chat_id, text, parse_mode: "Markdown")

# getUpdates has 0 mandatory params, 4 optional
ExGram.get_updates()
ExGram.get_updates(offset: 123, limit: 100)
```

### Return Values

Methods return `{:ok, result} | {:error, ExGram.Error.t()}`:

```elixir
case ExGram.send_message(chat_id, "Hello!") do
  {:ok, %ExGram.Model.Message{} = message} ->
    IO.puts("Message sent! ID: #{message.message_id}")
  
  {:error, %ExGram.Error{reason: reason}} ->
    Logger.error("Failed to send message: #{inspect(reason)}")
end
```

### Bang Methods (!)

Every method has a `!` variant that returns the result directly or raises:

```elixir
# Safe version
{:ok, message} = ExGram.send_message(chat_id, "Hello")

# Bang version - returns result or raises
message = ExGram.send_message!(chat_id, "Hello")
```

Use bang methods when you're confident the operation will succeed or when you want to let it fail.

## Method Documentation

View method documentation in IEx with `h`:

```elixir
iex> h ExGram.send_message

def send_message(chat_id, text, ops \\ [])

@spec send_message(
  chat_id :: integer() | String.t(),
  text :: String.t(),
  ops :: [
    parse_mode: String.t(),
    entities: [ExGram.Model.MessageEntity.t()],
    disable_web_page_preview: boolean(),
    disable_notification: boolean(),
    protect_content: boolean(),
    reply_to_message_id: integer(),
    allow_sending_without_reply: boolean(),
    reply_markup:
      ExGram.Model.InlineKeyboardMarkup.t()
      | ExGram.Model.ReplyKeyboardMarkup.t()
      | ExGram.Model.ReplyKeyboardRemove.t()
      | ExGram.Model.ForceReply.t()
    ]
) :: {:ok, ExGram.Model.Message.t()} | {:error, ExGram.Error.t()}
```

## Extra Options

All methods support three extra options:

### `token` - Use specific token

```elixir
ExGram.send_message("@channel", "Update!", token: "BOT_TOKEN")
```

### `bot` - Use named bot

```elixir
ExGram.send_message(chat_id, "Hello", bot: :my_bot)
```

The bot name is looked up in `Registry.ExGram` (populated by `ExGram` and bot framework).

### `debug` - Print HTTP response

```elixir
ExGram.send_message(chat_id, "Test", debug: true)
```

**Note:** Only use **one** of `token` or `bot`, not both.

## Common Use Cases

### Sending Messages from Background Tasks

```elixir
defmodule MyApp.Scheduler do
  def send_daily_report do
    users = MyApp.Users.get_subscribed_users()
    
    Enum.each(users, fn user ->
      message = generate_report(user)
      ExGram.send_message(user.telegram_id, message, bot: :my_bot)
    end)
  end
end
```

### Sending to Channels

```elixir
# No bot token in config
ExGram.send_message("@my_channel", "Update!", token: System.get_env("BOT_TOKEN"))
```

### Error Handling

```elixir
def send_with_retry(chat_id, text, retries \\ 3) do
  case ExGram.send_message(chat_id, text, bot: :my_bot) do
    {:ok, message} ->
      {:ok, message}
    
    {:error, %{reason: reason}} when retries > 0 ->
      Logger.warning("Send failed: #{inspect(reason)}, retrying...")
      :timer.sleep(1000)
      send_with_retry(chat_id, text, retries - 1)
    
    {:error, error} ->
      {:error, error}
  end
end
```

### Working with Files

```elixir
# By file ID
{:ok, message} = ExGram.send_document(chat_id, "BQACAgIAAxkBAAI...")

# By local path
{:ok, message} = ExGram.send_document(chat_id, {:file, "priv/report.pdf"})

# By content
pdf_content = generate_pdf()
{:ok, message} = ExGram.send_document(
  chat_id,
  {:file_content, pdf_content, "report.pdf"}
)
```

### Pinning Messages

```elixir
{:ok, %{message_id: msg_id}} = ExGram.send_message(chat_id, "Important!")
ExGram.pin_chat_message(chat_id, msg_id)
```

### Getting Bot Info

```elixir
{:ok, %ExGram.Model.User{username: username}} = ExGram.get_me(bot: :my_bot)
IO.puts("Bot username: @#{username}")
```

## Type Definitions

ExGram defines custom types for the Telegram API:

- `:string` → `String.t()`
- `:int` or `:integer` → `integer()`
- `:bool` or `:boolean` → `boolean()`
- `:file` → `{:file, String.t()}` (file path)
- `{:file_content, binary(), String.t()}` - file content with name
- `{:array, t}` → `[t]` (list of type)
- Any `ExGram.Model.*` struct

## Using Without the Framework

You can use ExGram purely as a library without the bot framework:

```elixir
# config/config.exs
config :ex_gram,
  token: "YOUR_BOT_TOKEN",
  adapter: ExGram.Adapter.Req

# No need to add ExGram to supervision tree

# lib/my_app.ex
defmodule MyApp do
  def notify_users(message) do
    users = get_users()
    
    Enum.each(users, fn user ->
      ExGram.send_message(user.telegram_id, message)
    end)
  end
end
```

Or without any config:

```elixir
ExGram.send_message("@channel", "Update!", token: "BOT_TOKEN")
```

## Complete Example: Notification System

```elixir
defmodule MyApp.Notifications do
  alias ExGram.Model.{InlineKeyboardMarkup, InlineKeyboardButton}
  
  def send_notification(user_id, type, data) do
    message = format_message(type, data)
    keyboard = build_keyboard(type, data)
    
    ExGram.send_message(
      user_id,
      message,
      parse_mode: "Markdown",
      reply_markup: keyboard,
      bot: :my_bot
    )
  end
  
  defp format_message(:order_shipped, %{order_id: id, tracking: tracking}) do
    """
    📦 *Order Shipped!*
    
    Order ##{id} has been shipped.
    Tracking: `#{tracking}`
    """
  end
  
  defp build_keyboard(:order_shipped, %{tracking_url: url}) do
    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "Track Package",
            url: url
          }
        ]
      ]
    }
  end
end
```

## Next Steps

- [Sending Messages](sending-messages.md) - DSL for simpler bots
- [Multiple Bots](multiple_bots.md) - Using `bot:` option effectively
- [Testing](testing.md) - Test adapter for low-level API calls
