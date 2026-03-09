# ExGram Cheatsheet

Quick reference for common ExGram patterns and functions.

## Configuration

```elixir
# config/config.exs
config :ex_gram,
  token: "BOT_TOKEN",
  adapter: ExGram.Adapter.Req
```

## Bot module example

```elixir
defmodule MyBot.Bot do
  @bot :my_bot
  
  use ExGram.Bot,
    name: @bot,
    setup_commands: true
  
  # Declare commands
  command("start")
  command("help", description: "Show help")
  
  # Declare regex patterns
  regex(:email, ~r/\b[\w._%+-]+@[\w.-]+\.[A-Z|a-z]{2,}\b/)
  
  # Add middlewares
  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(&my_middleware/2)
  
  # Init callback (optional)
  def init(opts) do
    # Setup before receiving updates
    :ok
  end
  
  # Handlers
  def handle({:command, "start", _}, context) do
    answer(context, "Hi!")
  end
end
```

## Supervision Tree

```elixir
children = [
  ExGram,  # Must come first
  {MyBot.Bot, [method: :polling, token: token]} 
]
```


## Handler Patterns

```elixir
# Commands
def handle({:command, "start", msg}, context)

# Text messages
def handle({:text, text, message}, context)

# Regex patterns (define with: regex(:name, ~r/pattern/))
def handle({:regex, :email, message}, context)

# Callback queries
def handle({:callback_query, callback}, context)

# Inline queries
def handle({:inline_query, query}, context)

# Location
def handle({:location, location}, context)

# Edited messages
def handle({:edited_message, edited_message}, context)

# Generic message
def handle({:message, message}, context)

# Default handler
def handle({:update, update}, context)
```

## DSL Functions - Sending

```elixir
# Text messages
answer(context, "Hello!")
answer(context, "Hello", parse_mode: "Markdown")

# Media
answer_photo(context, photo_id_or_file)
answer_document(context, doc_id_or_file)
answer_video(context, video_id_or_file)
answer_audio(context, audio_id_or_file)
answer_voice(context, voice_id_or_file)
answer_sticker(context, sticker_id)
answer_animation(context, animation_id)

# Callback queries
answer_callback(context, "Done!")
answer_callback(context, "Alert!", show_alert: true)

# Inline queries
answer_inline_query(context, results)
answer_inline_query(context, results, cache_time: 300)
```

## DSL Functions - Editing & Deleting

```elixir
# Edit message
edit(context, "New text")
edit(context, "New text", reply_markup: markup)

# Edit inline message
edit_inline(context, "New text")

# Edit only keyboard
edit_markup(context, new_markup)

# Delete message
delete(context)
delete(context, chat_id, message_id)
```

## DSL Functions - Chaining

```elixir
# Use result of previous action
context
|> answer("Sending photo...")
|> on_result(fn {:ok, message} ->
  # Do something with message
  :ok
end)
```

## File Formats

```elixir
# By Telegram file ID
"AgACAgIAAxkBAAI..."

# By local file path
{:file, "path/to/file.jpg"}

# By file content
{:file_content, binary_data, "filename.jpg"}
```

## Keyboards

```elixir
# Import the keyboard DSL
import ExGram.Dsl.Keyboard

# Simple inline keyboard
markup = keyboard :inline do
  row do
    button "Button 1", callback_data: "btn1"
    button "Button 2", callback_data: "btn2"
  end
  row do
    button "Button 3", callback_data: "btn3"
  end
end

# Use in different methods that accept reply_markup
answer(context, "Choose:", reply_markup: markup)

# With URL button
keyboard :inline do
  row do
    button "Visit", url: "https://example.com"
  end
end

# Reply keyboard (sticky keyboard)
keyboard :reply, [is_persistent: true] do
  row do
    reply_button "Help", style: "success"
  end
end
```

## Context Extractors

```elixir
# Chat/User info
extract_id(context)           # Chat ID (User ID in private chats and Chat ID in groups)
extract_user(context)         # User struct
extract_chat(context)         # Chat struct

# Message info
extract_message_id(context)   # Message id from any message type
extract_message_type(context) # :text, :photo, :document, etc.

# Query info
extract_callback_id(context)  # Callback query ID
extract_inline_id_params(context)  # Inline message params

# Update info
extract_update_type(context)  # :message, :callback_query, etc.
extract_response_id(context)  # Response ID for editing
```

## Update Types

```elixir
:message
:edited_message
:channel_post
:edited_channel_post
:inline_query
:chosen_inline_result
:callback_query
:shipping_query
:pre_checkout_query
:poll
:poll_answer
:my_chat_member
:chat_member
:chat_join_request
```

## Message Types

```elixir
:text
:photo
:video
:audio
:document
:voice
:sticker
:animation
:location
:contact
:poll
:dice
:game
:venue
```

## Low-Level API

```elixir
# Basic call
ExGram.send_message(chat_id, "Hello")

# With options
ExGram.send_message(chat_id, "Hello", parse_mode: "Markdown")

# With token
ExGram.send_message(chat_id, "Hello", token: "BOT_TOKEN")

# With named bot
ExGram.send_message(chat_id, "Hello", bot: :my_bot)

# Bang version (raises on error)
ExGram.send_message!(chat_id, "Hello")

# Common methods
ExGram.get_me()
ExGram.get_updates()
ExGram.send_photo(chat_id, photo)
ExGram.edit_message_text(chat_id, message_id, "New text")
ExGram.delete_message(chat_id, message_id)
ExGram.pin_chat_message(chat_id, message_id)
ExGram.get_chat(chat_id)
ExGram.get_chat_member(chat_id, user_id)
```

## Middleware

```elixir
# Function middleware
middleware(&my_middleware/2)

def my_middleware(context, opts) do
  # Process context
  context
end

# Module middleware
middleware(MyMiddleware)
middleware({MyMiddleware, opts})

# Built-in
middleware(ExGram.Middleware.IgnoreUsername)

# Add information to the extra field in `t:ExGram.Cnt.t/0`
context |> ExGram.Middleware.add_extra(:key, value)
context |> ExGram.Middleware.add_extra(%{key1: value1, key2: value2})

# Halt processing
context |> ExGram.Middleware.halt()
```

## Common Patterns

### Multi-step Conversation

```elixir
def handle({:command, "order", _}, context) do
  # Store state somewhere (ETS, Agent, Database)
  set_user_state(extract_id(context), :awaiting_item)
  answer(context, "What would you like to order?")
end

def handle({:text, text, _}, context) do
  case get_user_state(extract_id(context)) do
    :awaiting_item ->
      set_user_state(extract_id(context), {:awaiting_quantity, text})
      answer(context, "How many?")
    
    {:awaiting_quantity, item} ->
      clear_user_state(extract_id(context))
      answer(context, "Ordered #{text}x #{item}!")
    
    _ ->
      answer(context, "I don't understand")
  end
end
```

### Admin Check

```elixir
defmodule AdminMiddleware do
  use ExGram.Middleware
  
  def call(context, opts) do
    user_id = ExGram.Dsl.extract_id(context)
    admin_ids = Keyword.get(opts, :admins, [])
    
    if user_id in admin_ids do
      add_extra(context, :user_id, user_id)
    else
      context
      |> ExGram.Dsl.answer("⛔ Admin only")
      |> halt()
    end
  end
end
```

### Pagination

```elixir
import ExGram.Dsl.Keyboard

def handle({:command, "list", _}, context) do
  show_page(context, 1)
end

def handle({:callback_query, %{data: "page:" <> page}}, context) do
  page_num = String.to_integer(page)
  
  context
  |> answer_callback()
  |> show_page(page_num)
end

defp show_page(context, page) do
  items = get_items(page)
  
  markup = keyboard :inline do
    row do
      button "⬅️", callback_data: "page:#{page - 1}"
      button "#{page}", callback_data: "current"
      button "➡️", callback_data: "page:#{page + 1}"
    end
  end
  
  edit(context, format_items(items), reply_markup: markup)
end
```

## Debugging

```elixir
# Enable debug logging
config :logger, level: :debug

# Debug single request
ExGram.send_message(chat_id, "Test", debug: true)

# Log in handler
require Logger
def handle(update, context) do
  Logger.debug("Received: #{inspect(update)}")
  context
end
```

## Testing

```elixir
# Start bot in noup mode
{MyBot.Bot, [method: :noup, token: "test"]}

# Build test context
%ExGram.Cnt{
  update: update,
  name: :my_bot,
  halted: false,
  responses: []
}

# Test handler
result = MyBot.Bot.handle({:command, "start", ""}, context)
assert result.responses != []
```

## Resources

- [ExGram Hex Docs](https://hexdocs.pm/ex_gram)
- [Telegram Bot API](https://core.telegram.org/bots/api)
