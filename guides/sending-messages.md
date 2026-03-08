# Sending Messages

This guide covers the ExGram DSL for building and sending responses to your users.

## Understanding the DSL Philosophy

The ExGram DSL uses a **builder pattern**. DSL functions **build up** a list of actions on the context object. You **must return the context** from your handler, and ExGram will **execute all actions in order**.

### How It Works

```elixir
def handle({:command, "start", _msg}, context) do
  context
  |> answer("Welcome!")           # Action 1: queued
  |> answer("Here's a menu:")     # Action 2: queued
  |> answer_photo(photo_id)       # Action 3: queued
end  
# After handler returns, ExGram executes: action 1 → action 2 → action 3
```

**Key points:**
- DSL functions **build** actions, they don't execute immediately
- You **must return** the context for actions to execute
- Actions execute **in order** after your handler completes
- This is perfect for common/basic bot logic

### When NOT to Use the DSL

For complex bots with **background tasks**, **scheduled jobs**, or operations outside of handlers, use the [Low-Level API](low-level-api.md) instead:

```elixir
# In a background task or GenServer
def send_notification(user_id) do
  # Use Low-Level API directly
  ExGram.send_message(user_id, "Scheduled notification!", bot: :my_bot)
end
```

## Sending Text Messages

### `answer/2-4`

Send a text reply to the current chat.

```elixir
# Simple text
def handle({:command, "hello", _}, context) do
  answer(context, "Hello there!")
end

# With options
def handle({:command, "secret", _}, context) do
  answer(context, "🤫 Secret message", parse_mode: "Markdown", disable_notification: true)
end

# Multi-line
def handle({:command, "help", _}, context) do
  answer(context, """
  Available commands:
  /start - Start the bot
  /help - Show this help
  /settings - Configure settings
  """)
end
```

**Options:** `parse_mode`, `disable_web_page_preview`, `disable_notification`, `reply_to_message_id`, `reply_markup`

### Multiple Messages

Chain multiple `answer` calls to send several messages:

```elixir
def handle({:command, "story", _}, context) do
  context
  |> answer("Once upon a time...")
  |> answer("There was a bot...")
  |> answer("The end!")
end
```

## Sending Media

### `answer_photo/2-4`

Send photos:

```elixir
# By file ID (already uploaded to Telegram)
def handle({:command, "photo", _}, context) do
  answer_photo(context, "AgACAgIAAxkBAAI...")
end

# By local file path
def handle({:command, "local_photo", _}, context) do
  answer_photo(context, {:file, "priv/static/images/photo.jpg"})
end

# By file content
def handle({:command, "generated", _}, context) do
  image_binary = generate_image()
  answer_photo(context, {:file_content, image_binary, "generated.png"})
end

# With caption
def handle({:command, "captioned", _}, context) do
  answer_photo(context, photo_id, caption: "Look at this!", parse_mode: "Markdown")
end
```

### Other Media Functions

All media functions support the same three ways of providing files:

```elixir
# Documents
answer_document(context, file_or_id, opts \\ [])

# Videos
answer_video(context, video_or_id, opts \\ [])

# Audio
answer_audio(context, audio_or_id, opts \\ [])

# Voice messages
answer_voice(context, voice_or_id, opts \\ [])

# Stickers
answer_sticker(context, sticker_or_id, opts \\ [])

# Animations (GIFs)
answer_animation(context, animation_or_id, opts \\ [])
```

## Inline Keyboards

Create interactive buttons that users can press.

### Basic Inline Keyboard

```elixir
def handle({:command, "choose", _}, context) do
  markup = create_inline([
    [
      %{text: "Option A", callback_data: "option_a"},
      %{text: "Option B", callback_data: "option_b"}
    ],
    [
      %{text: "Cancel", callback_data: "cancel"}
    ]
  ])
  
  answer(context, "Choose an option:", reply_markup: markup)
end
```

### Using `create_inline_button/1`

For URL buttons and other types:

```elixir
def handle({:command, "links", _}, context) do
  markup = create_inline([
    [
      create_inline_button("Visit Website", url: "https://example.com"),
      create_inline_button("Join Channel", url: "https://t.me/channel")
    ]
  ])
  
  answer(context, "Check out these links:", reply_markup: markup)
end
```

### Handling Callback Queries

```elixir
def handle({:callback_query, %{data: "option_a"}}, context) do
  context
  |> answer_callback("You chose A!")
  |> edit("You selected Option A")
end

def handle({:callback_query, %{data: "option_b"}}, context) do
  context
  |> answer_callback("You chose B!")
  |> edit("You selected Option B")
end
```

## Callback Queries

### `answer_callback/2-3`

Always respond to callback queries to remove the loading indicator:

```elixir
# Simple acknowledgment
def handle({:callback_query, %{data: "click"}}, context) do
  answer_callback(context, "Button clicked!")
end

# Show alert (popup)
def handle({:callback_query, %{data: "alert"}}, context) do
  answer_callback(context, "This is an alert!", show_alert: true)
end

# Silent acknowledgment
def handle({:callback_query, _}, context) do
  answer_callback(context)
end
```

## Inline Queries

### `answer_inline_query/2-3`

Respond to inline queries (`@yourbot search term`):

```elixir
def handle({:inline_query, %{query: query}}, context) do
  results = search_results(query)
  |> Enum.map(fn result ->
    %{
      type: "article",
      id: result.id,
      title: result.title,
      description: result.description,
      input_message_content: %{
        message_text: result.content
      }
    }
  end)
  
  answer_inline_query(context, results, cache_time: 300)
end
```

See [Telegram InlineQueryResult docs](https://core.telegram.org/bots/api#inlinequeryresult) for result types.

## Editing Messages

### `edit/2-4`

Edit a previous message:

```elixir
# In callback query handler - edits the message with the button
def handle({:callback_query, %{data: "refresh"}}, context) do
  context
  |> answer_callback("Refreshing...")
  |> edit("Updated content at #{DateTime.utc_now()}")
end

# Edit with new markup
def handle({:callback_query, %{data: "next_page"}}, context) do
  new_markup = create_inline([[%{text: "Back", callback_data: "prev_page"}]])
  
  context
  |> answer_callback()
  |> edit("Page 2", reply_markup: new_markup)
end
```

### `edit_inline/2-4`

Edit inline query result messages:

```elixir
edit_inline(context, "Updated inline result")
```

### `edit_markup/2`

Update only the inline keyboard:

```elixir
def handle({:callback_query, %{data: "toggle"}}, context) do
  new_markup = create_inline([[%{text: "Toggled!", callback_data: "toggle"}]])
  
  context
  |> answer_callback()
  |> edit_markup(new_markup)
end
```

## Deleting Messages

### `delete/1-3`

Delete messages:

```elixir
# Delete the message that triggered the update
def handle({:callback_query, %{data: "delete"}}, context) do
  context
  |> answer_callback("Deleting...")
  |> delete()
end

# Delete specific message
def handle({:command, "cleanup", _}, context) do
  chat_id = extract_id(context)
  delete(context, chat_id, message_id)
end
```

## Chaining Results with `on_result/2`

Use the result of one action in the next action:

```elixir
def handle({:command, "pin", _}, context) do
  context
  |> answer("Important announcement!")
  |> on_result(fn {:ok, %{message_id: msg_id}} ->
    # Pin the message we just sent
    ExGram.pin_chat_message(extract_id(context), msg_id)
    :ok
  end)
end

def handle({:command, "forward_to_admin", _}, context) do
  admin_chat_id = Application.get_env(:my_app, :admin_chat_id)
  
  context
  |> answer("Message sent to admin!")
  |> on_result(fn {:ok, message} ->
    # Forward the confirmation to admin
    ExGram.forward_message(admin_chat_id, message.chat.id, message.message_id)
    :ok
  end)
end
```

**Note:** `on_result/2` receives the result of the previous action. Return `:ok` to continue the chain.

## Context Helper Functions

ExGram provides helper functions to extract information from the context:

### `extract_id/1`

Get the chat ID from the update:

```elixir
chat_id = extract_id(context)
```

### `extract_user/1`

Get the user who triggered the update:

```elixir
%{id: user_id, username: username} = extract_user(context)
```

### `extract_chat/1`

Get the chat where the update occurred:

```elixir
chat = extract_chat(context)
```

### `extract_message_id/1`

Get the message ID:

```elixir
message_id = extract_message_id(context)
```

### `extract_callback_id/1`

Get callback query ID (for answering callbacks):

```elixir
callback_id = extract_callback_id(context)
```

### `extract_update_type/1`

Get the update type:

```elixir
case extract_update_type(context) do
  :message -> # ...
  :callback_query -> # ...
  :inline_query -> # ...
end
```

### `extract_message_type/1`

Get the message type:

```elixir
case extract_message_type(context) do
  :text -> # ...
  :photo -> # ...
  :document -> # ...
end
```

### Other Helpers

```elixir
extract_response_id(context)      # Get response ID for editing
extract_inline_id_params(context) # Get inline message params
```

See [Cheatsheet](cheatsheet.md) for the complete list.

## Complete Example

Here's a bot that demonstrates multiple DSL features:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot, setup_commands: true

  command("start")
  command("menu")
  command("info")

  def handle({:command, "start", _}, context) do
    user = extract_user(context)
    
    context
    |> answer("Welcome, #{user.first_name}!")
    |> answer("I'm here to help you. Use /menu to see options.")
  end

  def handle({:command, "menu", _}, context) do
    markup = create_inline([
      [
        %{text: "📊 Stats", callback_data: "stats"},
        %{text: "⚙️ Settings", callback_data: "settings"}
      ],
      [
        %{text: "ℹ️ Info", callback_data: "info"},
        %{text: "❌ Close", callback_data: "close"}
      ]
    ])
    
    answer(context, "Main Menu:", reply_markup: markup)
  end

  def handle({:callback_query, %{data: "stats"}}, context) do
    user = extract_user(context)
    stats = get_user_stats(user.id)
    
    context
    |> answer_callback()
    |> edit("📊 Your Stats:\n\nMessages: #{stats.messages}\nCommands: #{stats.commands}")
  end

  def handle({:callback_query, %{data: "close"}}, context) do
    context
    |> answer_callback("Closing menu")
    |> delete()
  end

  defp get_user_stats(user_id) do
    # Fetch from database
    %{messages: 42, commands: 15}
  end
end
```

## Next Steps

- [Message Entities](message_entities.md) - Format messages without Markdown
- [Middlewares](middlewares.md) - Add preprocessing logic
- [Low-Level API](low-level-api.md) - Direct API calls for complex scenarios
- [Cheatsheet](cheatsheet.md) - Quick reference for all DSL functions
