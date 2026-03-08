# Middlewares

Middlewares are functions that run **before** your handler processes an update. They're perfect for authentication, logging, rate limiting, or enriching the context with additional data.

## What Are Middlewares?

A middleware is either:
- A module implementing the `ExGram.Middleware` behaviour
- A function with signature: `(Cnt.t(), opts :: any()) -> Cnt.t()`

Middlewares receive the context, modify it, and return it. The modified context is passed to the next middleware or handler.

## Using Built-in Middlewares

### `ExGram.Middleware.IgnoreUsername`

This middleware strips the bot's username from commands, allowing both `/start` and `/start@yourbot` to work identically.

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # Add middleware at module level
  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:command, "start", _}, context) do
    # Handles both /start and /start@my_bot
    answer(context, "Welcome!")
  end
end
```

**Why use this?**
In group chats, users often mention the bot explicitly (`/command@botname`). This middleware normalizes commands.

## Creating Custom Middlewares

### Function-based Middleware

The simplest approach is a function:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # Define middleware function
  middleware(&log_updates/2)

  # Middleware function
  def log_updates(context, _opts) do
    user = extract_user(context)
    update_type = extract_update_type(context)
    
    Logger.info("Update from #{user.id}: #{update_type}")
    
    context  # Return context
  end

  def handle({:command, "start", _}, context) do
    answer(context, "Hello!")
  end
end
```

### Module-based Middleware

For more complex logic, implement the `ExGram.Middleware` behaviour:

```elixir
defmodule MyBot.AuthMiddleware do
  @behaviour ExGram.Middleware

  def call(context, opts) do
    user = ExGram.Dsl.extract_user(context)
    
    if authorized?(user.id, opts) do
      # User is authorized, continue
      context
    else
      # User is not authorized, halt processing
      ExGram.Dsl.answer(context, "⛔ Access denied")
      |> Map.put(:halted, true)
    end
  end

  defp authorized?(user_id, opts) do
    allowed_users = Keyword.get(opts, :allowed_users, [])
    user_id in allowed_users
  end
end
```

Use it in your bot:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # Pass options to middleware
  middleware({MyBot.AuthMiddleware, [allowed_users: [123456, 789012]]})

  def handle({:command, "admin", _}, context) do
    # Only authorized users reach here
    answer(context, "Admin panel: ...")
  end
end
```

## Halting the Middleware Chain

Set `halted: true` to stop processing:

```elixir
def call(context, _opts) do
  if rate_limited?(context) do
    context
    |> ExGram.Dsl.answer("⏱️ Please wait before sending another command")
    |> Map.put(:halted, true)
  else
    context
  end
end
```

When `halted: true`, no further middlewares or handlers execute.

### `middleware_halted` vs `halted`

- `middleware_halted: true` - Stop middleware chain, but run handler
- `halted: true` - Stop everything (middlewares + handler)

## Enriching Context with Extra Data

Add custom data to `context.extra` for use in handlers:

```elixir
defmodule MyBot.UserDataMiddleware do
  @behaviour ExGram.Middleware

  def call(context, _opts) do
    user = ExGram.Dsl.extract_user(context)
    user_data = fetch_user_from_database(user.id)
    
    # Add to context.extra
    ExGram.Cnt.add_extra(context, %{
      user_role: user_data.role,
      user_premium: user_data.premium?,
      user_lang: user_data.language
    })
  end

  defp fetch_user_from_database(user_id) do
    # Database lookup
    %{role: :user, premium?: false, language: "en"}
  end
end
```

Use in handlers:

```elixir
def handle({:command, "premium_feature", _}, context) do
  if context.extra[:user_premium] do
    answer(context, "✨ Premium feature unlocked!")
  else
    answer(context, "⭐ This feature requires premium")
  end
end
```

## Command and Regex Macros

The `command/2` and `regex/2` macros are actually middleware builders:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # These register commands and patterns
  command("start", description: "Start the bot")
  command("help", description: "Get help")
  
  regex(:email, ~r/\b[A-Za-z0-9._%+-]+@/)
  regex(:url, ~r|https?://[^\s]+|)

  # Handlers match against registered commands/patterns
  def handle({:command, "start", _}, context), do: answer(context, "Hi!")
  def handle({:regex, :email, _}, context), do: answer(context, "Found an email!")
end
```

With `setup_commands: true`, commands are automatically registered with Telegram's BotFather menu.

## Multiple Middlewares

Middlewares execute in the order they're defined:

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot

  # Execution order: 1 → 2 → 3 → handler
  middleware(&log_middleware/2)           # 1
  middleware(MyBot.AuthMiddleware)        # 2
  middleware(ExGram.Middleware.IgnoreUsername)  # 3

  def handle({:command, "start", _}, context) do
    answer(context, "Hello!")
  end
end
```

If middleware 2 halts, middleware 3 and the handler don't run.

## Common Middleware Patterns

### Rate Limiting

```elixir
defmodule MyBot.RateLimitMiddleware do
  @behaviour ExGram.Middleware

  def call(context, opts) do
    user_id = ExGram.Dsl.extract_user(context).id
    limit = Keyword.get(opts, :per_minute, 10)
    
    case check_rate_limit(user_id, limit) do
      :ok ->
        context
      
      {:error, retry_after} ->
        context
        |> ExGram.Dsl.answer("⏱️ Rate limited. Try again in #{retry_after}s")
        |> Map.put(:halted, true)
    end
  end

  defp check_rate_limit(user_id, limit) do
    # Check Redis/ETS for request count
    :ok
  end
end
```

### Language Detection

```elixir
defmodule MyBot.LanguageMiddleware do
  @behaviour ExGram.Middleware

  def call(context, _opts) do
    user = ExGram.Dsl.extract_user(context)
    
    # Detect from user's Telegram language or database
    lang = user.language_code || "en"
    
    ExGram.Cnt.add_extra(context, %{language: lang})
  end
end
```

### Command Analytics

```elixir
def analytics_middleware(context, _opts) do
  case ExGram.Dsl.extract_update_type(context) do
    :message ->
      if command = extract_command(context) do
        track_command(command)
      end
    _ -> :ok
  end
  
  context
end

defp extract_command(%{update: %{message: %{text: "/" <> cmd}}}), do: cmd
defp extract_command(_), do: nil
```

## Testing Middlewares

Test middlewares by creating a context and calling them:

```elixir
defmodule MyBot.AuthMiddlewareTest do
  use ExUnit.Case
  
  test "allows authorized users" do
    context = build_context(user_id: 123456)
    opts = [allowed_users: [123456]]
    
    result = MyBot.AuthMiddleware.call(context, opts)
    
    refute result.halted
  end
  
  test "blocks unauthorized users" do
    context = build_context(user_id: 999999)
    opts = [allowed_users: [123456]]
    
    result = MyBot.AuthMiddleware.call(context, opts)
    
    assert result.halted
  end
end
```

## Next Steps

- [Handling Updates](handling-updates.md) - Understanding handlers
- [Sending Messages](sending-messages.md) - DSL for building responses
- [Multiple Bots](multiple_bots.md) - Running multiple bots
