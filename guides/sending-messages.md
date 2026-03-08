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

### Wrong patterns

#### Not carrying context updates

This won't work as expected, Elixir it's immutable, so the updated context need to be passed to the next actions all the way to the end.

```elixir
def handle({:command, "start", _msg}, context) do
  answer(context, "Welcome!") # ❌ This will never be sent!!
  answer(context, "Here's a menu:") # ❌ This will never be sent!!
  answer_photo(context, photo_id)
end
```

#### Doing actions, and then other things

There are two common got-chas.

The first one is, queueing actions, but not returning the context, this will make the actions to not be executed at all.

```elixir
def handle({:command, "start", msg}, context) do
  answer(context, "Welcome!") # ❌ This will never be sent!!

  MyBot.update_user_stats(extract_user(msg))
end

# Correct:
def handle({:command, "start", msg}, context) do
  MyBot.update_user_stats(extract_user(msg))

  answer(context, "Welcome!")
end
```

The second common mistake is the order if you mix DSL and non DSL:

```elixir
def handle({:command, "start", msg}, context) do
  context = answer(context, "Welcome!")

  # ❌ This will be sent BEFORE the "Welcome!" message, because the DSL actions are enqueued and executed AFTER the handle/2 method
  ExGram.send_photo(extract_chat_id(msg), photo_id, bot: context.name) 
  
  context
end

# Correct:
def handle({:command, "start", msg}, context) do
  chat_id = extract_id(msg) 
  # Using on_result allow you to do actions after the previous action
  context 
  |> answer("Welcome!")
  |> on_result(fn 
    {:ok, _}, name -> 
      ExGram.send_photo(chat_id, photo_id, bot: name)
    error, _name -> 
      error
  end)
end
```

### When NOT to Use the DSL

The DSL is really powerful and helps to make the bot's logic easier to follow, but there are cases where you will need to use the [Low-Level API](./low-level-api.md), for example:

- There are still no DSL action for the method you want. The DSL has been created as needed, so many methods still don't have a DSL created. Feel free to open an issue or a pull request 😄
- For complex bots with **background tasks**, **scheduled jobs**, or operations outside of handlers, in this cases you can't use the DSL at all.

```elixir
# In a background task or GenServer
def send_notification(user_id) do
  # Use Low-Level API directly
  ExGram.send_message(user_id, "Scheduled notification!", bot: :my_bot)
end
```

Read more about the Low-Level API in [this guide](./low-level-api.md)

## Sending Text Messages

### `answer/2-4`

Send a text message to the current chat.

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

**Options:** All the `ExGram.send_message` options, you can see them in [the documentation](https://hexdocs.pm/ex_gram/ExGram.html#send_message/3)

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

All the fields that are files, will support three ways of sending that file:

- String: This is a file_id previously received in Telegram responses or messages.
- `{:file, "/path/to/file"}`: This will read the file and send it 
- `{:file_content, "content", "filename.jpg"}`: Will send the "content" directly. It can be a `String.t`, `iodata()` or a `Enum.t()`, useful for streaming data directly without loading everything in memory.

For now only `answer_document` has a DSL method, we'll add more DSL for sending media files

```elixir
# Documents
answer_document(context, {:file, "/path/to/document.txt"}, opts \\ [])
```

## Keyboards

Create interactive buttons that users can press.

### Inline Keyboard

There is a neat DSL to create keyboards!

```elixir
import ExGram.Dsl.Keyboard # It is not added by default, you have to import it

def handle({:command, "choose", _}, context) do
  markup = 
    keyboard :inline do
      row do
        inline_button "Option A", callback_data: "option_a"
        inline_button "Option B", callback_data: "option_b"
      end
      
      row do
        inline_button "Cancel", callback_data: "cancel"
      end
    end
  
  answer(context, "Choose an option:", reply_markup: markup)
end
```

The `inline_button` accepts all the options that the `ExGram.Model.InlineKeyboardButton` accepts, for example:

```elixir
inline_button "Visit website", url: "https://example.com", style: "success"
```

#### Handling Callback Queries

Just as a reminder, the callback_data it's handled in the bot with the `:callback_query` handler

```elixir
def handle({:callback_query, %{data: "option_a"}}, context) do
  context
  |> answer_callback("You chose A!")
  |> edit("You selected Option A")
end
```

### Reply keyboards

This are the keyboards that pop up at the botton of the screen. You can create them also with the DSL.

```elixir
keyboard :reply do
  row do
    reply_button "Help", style: "success"
    reply_button "Send my location", request_location: true, style: "danger"
  end
end
```

This keyboards accept more options too, check [the documentation](https://hexdocs.pm/ex_gram/ExGram.Model.ReplyKeyboardMarkup.html) for available options:

```elixir
keyboard :reply, [is_persistent: true, one_time_keyboard: true, resize_keyboard: true] do
  row do
    reply_button "Help", style: "success"
  end
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
  new_markup = keyboard do
    row do
      button "Toggled!", callback_data: "toggle"
    end
  end
  
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
  msg = %{chat_id: chat_id, message_id: message_id}
  delete(context, msg)
end
```

## Chaining Results with `on_result/2`

Tap into the execution chain and do something with the result of the previous action.

The callback receives two parameters:
- result: `{:ok, x} | {:error, error}`
- name: The bot's name

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
  |> on_result(fn 
    {:ok, message}, name ->
      # Forward the confirmation to admin
      ExGram.forward_message(admin_chat_id, extract_id(message), extract_message_id(message), bot: name)
      
    error, _name -> 
      error
  end)
end
```

**Note:** `on_result/2` receives the result of the previous action. What you return will be treated as the new result of that action. 

## Context Helper Functions

ExGram provides helper functions to extract information from the context:

### `extract_id/1`

Get the origin id from the update, if it's a chat, will be the chat id, if it's a private conversation will be the user id.

Used to know who to answer.

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

Get callback query ID

```elixir
callback_id = extract_callback_id(context)
```

### `extract_update_type/1`

Get the update type:

```elixir
case extract_update_type(update) do
  :message -> # ...
  :callback_query -> # ...
  :inline_query -> # ...
end
```

### `extract_message_type/1`

Get the message type:

```elixir
case extract_message_type(message) do
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

## Complete Example

Here's a bot that demonstrates multiple DSL features:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot, setup_commands: true
  
  import ExGram.Dsl.Keyboard

  command("start", description: "Start")
  command("menu", description: "Show menu")
  command("info", description: "Information")

  def handle({:command, :start, _}, context) do
    user = extract_user(context)
    
    context
    |> answer("Welcome, #{user.first_name}!")
    |> answer("I'm here to help you. Use /menu to see options.")
  end

  def handle({:command, :menu, _}, context) do
    markup = keyboard :inline do
      row do
        button "📊 Stats", callback_data: "stats"
        button "⚙️ Settings", callback_data: "settings"
      end
      
      row do
        button "ℹ️ Info", callback_data: "info"
        button "❌ Close", callback_data: "close"
      end
    end
    
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

- [Message Entities](message_entities.md) - Format messages without Markdown or HTML
- [Middlewares](middlewares.md) - Add preprocessing logic
- [Low-Level API](low-level-api.md) - Direct API calls for complex scenarios
- [Cheatsheet](cheatsheet.md) - Quick reference for all DSL functions
