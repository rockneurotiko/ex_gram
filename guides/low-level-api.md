# Low-Level API

The low-level API provides direct access to all Telegram Bot API methods without the DSL framework. This is useful for:

- **Complex applications** with background tasks or scheduled jobs
- **Fine-grained control** over requests and responses
- **Library usage** without the bot framework
- **Direct integration** with other systems

## How It Works

ExGram's low-level API is **automatically generated** from an up-to-date JSON description of the Telegram Bot API using the [telegram_api_json](https://github.com/rockneurotiko/telegram_api_json) project.

### The Generation Process

1. The `telegram_api_json` project scrapes the [Telegram Bot API documentation](https://core.telegram.org/bots/api)
2. It produces a standardized JSON file with all methods, parameters, and models
3. A Python script ([`extractor.py`](../extractor.py)) reads this JSON and generates Elixir code in [`lib/ex_gram.ex`](../lib/ex_gram.ex)
4. As a result, `ExGram` have all the available methods and `Exgram.Model.*` all the models, both with proper typespecs and documentation

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

### `bot` - Use named bot

```elixir
ExGram.send_message(chat_id, "Hello", bot: :my_bot)
```

The bot name has to match to a defined AND started bot, the name is the one you write in `use ExGram.Bot, name: :my_bot`, and you can always get the name of a bot from the module with `MyBot.name()`

**Note:** Only use **one** of `token` or `bot`, not both.

### `token` - Use specific token

```elixir
ExGram.send_message("@channel", "Update!", token: "BOT_TOKEN")
```

### `debug` - Print HTTP response

```elixir
ExGram.get_me(debug: true)

# 16:37:49.397 [info] Path: "/bot<token>/getMe"
body: %{}
```

**Warning:** Do not use this in production, it will log your bot's tokens

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

### Working with not supported on the DSL

```elixir
# By file ID
{:ok, message} = ExGram.send_photo(chat_id, "BQACAgIAAxkBAAI...")

# By local path
{:ok, message} = ExGram.send_photo(chat_id, {:file, "priv/image.png"})

# By content
image_stream = generate_image_stream()
{:ok, message} = ExGram.send_photo(chat_id, {:file_content, image_stream, "image.png"})
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

## Using Without the Framework

You can use ExGram purely as a library without the bot framework:

```elixir
# config/config.exs
config :ex_gram,
  token: "YOUR_BOT_TOKEN",
  adapter: ExGram.Adapter.Req

# lib/my_app/application.ex
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
  # You can still use the ExGram.Dsl.* if you want, they are independent
  import ExGram.Dsl.Keyboard
  
  alias ExGram.Dsl.MessageEntityBuilder, as: B
  alias ExGram.Model.{InlineKeyboardMarkup, InlineKeyboardButton}
  
  def send_notification(user_id, type, data) do
    {message, entities} = format_message(type, data)
    keyboard = build_keyboard(type, data)
    
    ExGram.send_message(user_id, message, reply_markup: keyboard, entities: entities, bot: :my_bot)
  end
  
  defp format_message(:order_shipped, %{order_id: id, tracking: tracking}) do
    header = B.join(["📦", B.bold("Order Shipped!")])
    order = B.join([
      B.join([B.bold("Order"), B.code("##{id}"), "has been shipped"]),
      B.join([B.bold("Tracking:"), B.url(tracking)])
    ], "\n")
    
    B.join([header, order], "\n\n")
  end
  
  defp build_keyboard(:order_shipped, %{tracking_url: url}) do
    keyboard :inline do
      row do
        button "Track Package", url: url
      end
    end
  end
end
```

## Next Steps

- [Multiple Bots](multiple_bots.md) - Using `bot:` option effectively
- [Testing](testing.md) - Test adapter for low-level API calls
