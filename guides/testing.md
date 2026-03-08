# Testing

This guide covers basic testing strategies for ExGram bots.

## Testing Without Updates: `:noup` Mode

The `:noup` mode starts your bot without receiving any updates. This is useful for offline testing of initialization logic or testing the low-level API.

### Setup

In your test configuration or test setup:

```elixir
# test/my_bot_test.exs
defmodule MyBotTest do
  use ExUnit.Case
  
  setup do
    # Start bot in noup mode
    {:ok, _pid} = start_supervised({MyBot.Bot, [method: :noup, token: "test_token"]})
    :ok
  end
  
  test "bot initializes correctly" do
    # Your test here
  end
end
```

Or configure it application-wide for tests:

```elixir
# config/test.exs
config :my_app, :bot_method, :noup
```

### What `:noup` Does

- Starts the bot process
- Runs `init/1` callback (if defined)
- Does **not** fetch updates
- Bot remains idle until manually called

### Testing Initialization

```elixir
defmodule MyBot.Bot do
  use ExGram.Bot, name: :my_bot
  
  def init(opts) do
    # This runs even in :noup mode
    send(self(), :initialized)
    :ok
  end
end

# Test
test "bot initialization sends message" do
  assert_receive :initialized, 1000
end
```

## Testing Low-Level API Calls

You can test direct API calls by mocking the HTTP adapter or using ExGram's test adapter.

### Using Test Configuration

```elixir
# config/test.exs
config :ex_gram,
  token: "test_token",
  adapter: ExGram.Adapter.Test

# Test
defmodule MyApp.NotificationsTest do
  use ExUnit.Case
  
  test "sends notification with correct format" do
    chat_id = 123456
    
    result = MyApp.Notifications.send_notification(chat_id, :order_shipped, %{
      order_id: "ORD-123",
      tracking: "TRACK-456"
    })
    
    assert {:ok, %ExGram.Model.Message{}} = result
  end
end
```

**Note:** `ExGram.Adapter.Test` returns mock responses for all API calls.

## Testing Handlers

Test your handler logic by creating mock contexts:

```elixir
defmodule MyBot.HandlerTest do
  use ExUnit.Case
  
  alias ExGram.Cnt
  alias ExGram.Model.{Update, Message, User, Chat}
  
  test "start command responds with welcome message" do
    context = build_context(
      update: build_update(:command, "/start"),
      user_id: 123456
    )
    
    result = MyBot.Bot.handle({:command, "start", ""}, context)
    
    # Check that answer was queued
    assert result.responses != []
    assert Enum.any?(result.responses, fn
      {:answer, _, ["Hi!"]} -> true
      _ -> false
    end)
  end
  
  # Helper to build test context
  defp build_context(opts) do
    update = Keyword.get(opts, :update)
    
    %Cnt{
      update: update,
      name: :my_bot,
      halted: false,
      middleware_halted: false,
      commands: [],
      responses: [],
      extra: %{}
    }
  end
  
  # Helper to build test updates
  defp build_update(:command, text) do
    %Update{
      update_id: 1,
      message: %Message{
        message_id: 1,
        date: DateTime.utc_now() |> DateTime.to_unix(),
        text: text,
        from: %User{
          id: 123456,
          is_bot: false,
          first_name: "Test",
          username: "testuser"
        },
        chat: %Chat{
          id: 123456,
          type: "private"
        }
      }
    }
  end
end
```

## Testing Middlewares

Test middlewares in isolation:

```elixir
defmodule MyBot.AuthMiddlewareTest do
  use ExUnit.Case
  
  alias MyBot.AuthMiddleware
  
  test "allows authorized users" do
    context = build_context(user_id: 123456)
    opts = [allowed_users: [123456]]
    
    result = AuthMiddleware.call(context, opts)
    
    refute result.halted
  end
  
  test "blocks unauthorized users" do
    context = build_context(user_id: 999999)
    opts = [allowed_users: [123456]]
    
    result = AuthMiddleware.call(context, opts)
    
    assert result.halted
  end
  
  test "adds responses when blocking" do
    context = build_context(user_id: 999999)
    opts = [allowed_users: [123456]]
    
    result = AuthMiddleware.call(context, opts)
    
    assert result.responses != []
  end
end
```

## Testing with ExUnit

### Basic Test Structure

```elixir
defmodule MyBot.BotTest do
  use ExUnit.Case, async: true
  
  setup do
    # Setup code
    :ok
  end
  
  describe "command handlers" do
    test "handles /start command" do
      # Test code
    end
    
    test "handles /help command" do
      # Test code
    end
  end
  
  describe "callback queries" do
    test "handles button press" do
      # Test code
    end
  end
end
```

### Using Mox for HTTP Mocking

For more control over HTTP responses:

```elixir
# In mix.exs
{:mox, "~> 1.0", only: :test}

# Define mock in test_helper.exs
Mox.defmock(MyApp.HTTPMock, for: ExGram.Adapter)

# In test
setup :verify_on_exit!

test "handles API error gracefully" do
  expect(MyApp.HTTPMock, :request, fn _method, _url, _body, _opts ->
    {:error, %ExGram.Error{reason: :network_error}}
  end)
  
  # Test error handling
end
```

## Testing Best Practices

### 1. Test Business Logic Separately

Extract business logic from handlers and test it independently:

```elixir
defmodule MyBot.Logic do
  def should_allow_access?(user_id) do
    # Logic here
  end
end

# Test the logic directly
test "allows premium users" do
  assert MyBot.Logic.should_allow_access?(12345)
end
```

### 2. Use Factories for Test Data

```elixir
defmodule MyBot.Factory do
  def build_context(attrs \\ %{}) do
    Map.merge(%Cnt{
      update: build_update(),
      name: :my_bot,
      halted: false,
      responses: []
    }, attrs)
  end
  
  def build_update(type \\ :message) do
    # Build different update types
  end
end
```

### 3. Test Edge Cases

```elixir
test "handles empty message" do
  context = build_context(update: build_update(:command, ""))
  result = MyBot.Bot.handle({:command, "search", ""}, context)
  
  # Assert appropriate error message
end

test "handles very long messages" do
  long_text = String.duplicate("a", 5000)
  context = build_context(text: long_text)
  
  # Assert message is truncated or rejected
end
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/my_bot_test.exs

# Run specific test
mix test test/my_bot_test.exs:42

# Run with coverage
mix test --cover
```

## Next Steps

- [Cheatsheet](cheatsheet.md) - Quick reference for testing helpers
- [Low-Level API](low-level-api.md) - Direct API calls for complex tests
- [Middlewares](middlewares.md) - Testing middleware logic
