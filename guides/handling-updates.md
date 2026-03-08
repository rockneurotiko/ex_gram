# Handling Updates

This guide explains how to handle different types of updates from Telegram in your ExGram bot.

## The `handle/2` Function

Every bot must implement the `handle/2` function. It receives:

1. **Update tuple** - Different tuple patterns for different update types
2. **Context** - A `%ExGram.Cnt{}` struct with update information

```elixir
def handle(update_tuple, context) do
  # Process the update and return context
  context
end
```

The context contains:
- `update` - The full [Update](https://core.telegram.org/bots/api#update) object
- `name` - Your bot's name (important for multiple bots)
- `extra` - Custom data from middlewares
- Internal fields used by ExGram

## Update Patterns

ExGram parses updates into convenient tuples for pattern matching.

### Commands

Matches messages starting with `/command`.

```elixir
def handle({:command, "start", msg}, context) do
  answer(context, "Welcome! You sent: #{msg}")
end

def handle({:command, "help", _msg}, context) do
  answer(context, """
  Available commands:
  /start - Start the bot
  /help - Show this help
  /settings - Configure settings
  """)
end
```

The `msg` parameter contains any text after the command:
- `/start` → `msg = ""`
- `/start hello world` → `msg = "hello world"`

You can also declare commands at the module level:

```elixir
command("start")
command("help", description: "Show help message")
command("settings", description: "Configure your settings")
```

With `setup_commands: true`, these are automatically registered with Telegram.

### Plain Text

Matches regular text messages (respects [privacy mode](https://core.telegram.org/bots#privacy-mode)).

```elixir
def handle({:text, text, message}, context) do
  cond do
    String.contains?(text, "hello") ->
      answer(context, "Hello to you too!")
    
    String.length(text) > 100 ->
      answer(context, "That's a long message!")
    
    true ->
      answer(context, "You said: #{text}")
  end
end
```

### Regex Patterns

Define regex patterns at module level and match against them:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # Define regex patterns
  regex(:email, ~r/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/)
  regex(:phone, ~r/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/)

  def handle({:regex, :email, message}, context) do
    answer(context, "I detected an email address in your message!")
  end

  def handle({:regex, :phone, message}, context) do
    answer(context, "That looks like a phone number!")
  end
end
```

### Callback Queries

Handles button presses from inline keyboards.

```elixir
def handle({:callback_query, %{data: "button_" <> id} = callback}, context) do
  context
  |> answer_callback("Processing button #{id}")
  |> answer("You clicked button #{id}")
end

def handle({:callback_query, %{data: "delete"}}, context) do
  context
  |> answer_callback("Deleting message...")
  |> delete()
end
```

See [Sending Messages](sending-messages.md) for creating inline keyboards.

### Inline Queries

Handles inline queries (e.g., `@yourbot search term`).

```elixir
def handle({:inline_query, query}, context) do
  results = [
    %{
      type: "article",
      id: "1",
      title: "Result 1",
      input_message_content: %{message_text: "You selected result 1"}
    },
    %{
      type: "article",
      id: "2",
      title: "Result 2",
      input_message_content: %{message_text: "You selected result 2"}
    }
  ]

  answer_inline_query(context, results)
end
```

### Location Messages

Handles location sharing.

```elixir
def handle({:location, %{latitude: lat, longitude: lon}}, context) do
  answer(context, "You're at #{lat}, #{lon}. Thanks for sharing!")
end
```

### Edited Messages

Handles message edits.

```elixir
def handle({:edited_message, edited_msg}, context) do
  # You can choose to process edited messages differently
  # or ignore them entirely
  Logger.info("Message #{edited_msg.message_id} was edited")
  context
end
```

### Generic Message Handler

Catches any message that doesn't match other patterns.

```elixir
def handle({:message, message}, context) do
  cond do
    message.photo ->
      answer(context, "Nice photo!")
    
    message.document ->
      answer(context, "Thanks for the document!")
    
    message.sticker ->
      answer(context, "Cool sticker!")
    
    message.voice ->
      answer(context, "I received your voice message!")
    
    true ->
      answer(context, "I received your message, but I'm not sure what to do with it.")
  end
end
```

### Default Handler

Catches all other updates.

```elixir
def handle({:update, update}, context) do
  Logger.debug("Received unhandled update: #{inspect(update)}")
  context
end
```

## The Context (`%ExGram.Cnt{}`)

The context struct contains:

```elixir
%ExGram.Cnt{
  update: %ExGram.Model.Update{},  # Full Telegram update
  name: :my_bot,                    # Your bot's name
  halted: false,                    # Stop processing?
  middleware_halted: false,         # Stop middleware chain?
  commands: [...],                  # Registered commands
  extra: %{}                        # Custom data from middlewares
}
```

### Adding Extra Data

Middlewares can add custom data to `context.extra`:

```elixir
# In a middleware
def call(context, _opts) do
  user_id = extract_id(context)
  extra_data = %{user_role: fetch_user_role(user_id)}
  
  ExGram.Cnt.add_extra(context, extra_data)
end

# In your handler
def handle({:command, "admin", _msg}, context) do
  case context.extra[:user_role] do
    :admin -> answer(context, "Admin panel: ...")
    _ -> answer(context, "Access denied")
  end
end
```

## The `init/1` Callback

The optional `init/1` callback runs once before processing updates. Use it to initialize your bot:

```elixir
def init(opts) do
  # opts contains [:bot, :token]
  ExGram.set_my_description!(
    description: "This bot helps you manage tasks",
    bot: opts[:bot]
  )
  
  ExGram.set_my_name!(
    name: "TaskBot",
    token: opts[:token]
  )
  
  ExGram.set_my_commands!(
    commands: [
      %{command: "start", description: "Start the bot"},
      %{command: "help", description: "Get help"},
      %{command: "tasks", description: "View your tasks"}
    ],
    bot: opts[:bot]
  )
  
  :ok
end
```

**Note:** If you use `setup_commands: true`, commands are automatically registered. Use `init/1` for additional setup like bot name and description.

## Pattern Matching Tips

### Multiple Clauses

Use multiple function clauses for clean code:

```elixir
def handle({:command, "start", _}, context), do: answer(context, "Welcome!")
def handle({:command, "help", _}, context), do: show_help(context)
def handle({:command, "about", _}, context), do: show_about(context)

def handle({:callback_query, %{data: "yes"}}, context) do
  answer_callback(context, "You chose yes!")
end

def handle({:callback_query, %{data: "no"}}, context) do
  answer_callback(context, "You chose no!")
end

def handle({:text, text, _msg}, context) when is_binary(text) do
  answer(context, "Echo: #{text}")
end

def handle(_update, context), do: context
```

### Guards

Use guards for additional filtering:

```elixir
def handle({:text, text, _msg}, context) when byte_size(text) > 500 do
  answer(context, "Please send shorter messages (max 500 characters)")
end

def handle({:text, text, _msg}, context) when text in ["hi", "hello", "hey"] do
  answer(context, "Hello there!")
end
```

### Extracting Data

Pattern match to extract specific fields:

```elixir
def handle({:message, %{from: %{id: user_id, username: username}}}, context) do
  answer(context, "Hello @#{username} (ID: #{user_id})")
end

def handle({:callback_query, %{from: user, data: data}}, context) do
  Logger.info("User #{user.id} clicked: #{data}")
  answer_callback(context, "Got it!")
end
```

## Next Steps

- [Sending Messages](sending-messages.md) - Learn the DSL for building responses
- [Middlewares](middlewares.md) - Add preprocessing logic to your bot
- [Cheatsheet](cheatsheet.md) - Quick reference for all patterns
