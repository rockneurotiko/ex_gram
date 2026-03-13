# Testing

ExGram ships with a test adapter that intercepts Telegram API calls, making it easy to test bots without hitting real servers. The adapter supports per-process isolation for async tests and provides stub/expect/verify semantics similar to [Mox](https://hexdocs.pm/mox) and [Req.Test](https://hexdocs.pm/req/Req.Test.html)

## Setup

### Global Configuration

Configure ExGram and your bot to use the test adapter in test environment:

```elixir
# config/test.exs
config :ex_gram,
  token: "test_token",
  adapter: ExGram.Adapter.Test
  
config :my_app, MyBot.Bot,
  token: "test_token",
  method: :test,
  username: "testbot", # Setting a username we skip the get_me call on startup
  setup_commands: false # Setting setup_commands: false we skip setting up the commands on startup

```

This tells ExGram to:
- Use `ExGram.Adapter.Test` to intercept API calls
- Use `method` `:test` (which is `ExGram.Updates.Test`) for pushing test updates (instead of polling or webhook)
- Fake username and disable setup_commands, so starting the application don't fail.

The bot's options has to be passed on startup, this is how I recommend doing it, a config entry for your bot's module, and then something like this in your `application.ex`:

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    bot_config = Application.get_env(:my_app, MyApp.Bot, [])
  
    children = [
      # ... your other children
      {MyApp.Bot, bot_config}
      # ...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Bot configuration

### Starting the Adapter

The test adapter uses [NimbleOwnership](https://hexdocs.pm/nimble_ownership) for per-process isolation. You need to start it before running tests.

**Option A: In your supervision tree (for applications)**

Since the bots do some calls to the Telegram API on start, if you have your bot in your application tree, you need to start the test adapter before.

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    bot_config = Application.get_env(:my_app, MyApp.Bot, [])
    
    app_children = [
      # ... your other children
      {MyApp.Bot, bot_config}
      # ...
    ]
    
    # Notife the `test_children()` call
    children = test_children() ++ app_children

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp test_children do
    if Mix.env() == :test do
      [ExGram.Adapter.Test]
    else
      []
    end
  end
end
```

**Option B: In test_helper.exs (for libraries)**

If you don't start your bot on the application tree (for example, you can decide to not start it on :test), you can just start the test adapter on the test_helper

```elixir
# test/test_helper.exs
{:ok, _} = ExGram.Test.start_link()

ExUnit.start()
```


### A Minimal Test

Here's a complete working test to test your Bot's logic asynchronous and isolated.

```elixir
defmodule MyApp.NotificationsTest do
  use ExUnit.Case, async: true
  
  setup {ExGram.Test, :verify_on_exit!}
  
  describe "handle start command" do
    setup context do
      # Start an isolated instance of your bot with an unique name
      {bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot)
        
      {:ok, bot_name: bot_name}
    end
    
    test "/start command returns welcome message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        text = body[:text]
        assert text =~ "Welcome", "Expected welcome message, got body: #{inspect(body)}"

        {:ok, %{message_id: 1, date: 0, chat: %{id: @chat_id, type: "private"}, text: "Response"}}
      end)

      update = build_command_update("/start")
      # push_update is synchronous by default - when it returns the handler has already run
      ExGram.Test.push_update(bot_name, update)
    end
  end
  
  # Helper to build a command update
  defp build_command_update(text) do
    %ExGram.Model.Update{
      update_id: System.unique_integer([:positive]),
      message: %ExGram.Model.Message{
        message_id: System.unique_integer([:positive]),
        date: DateTime.utc_now(),
        chat: %ExGram.Model.Chat{id: @chat_id, type: "private"},
        from: %ExGram.Model.User{id: @chat_id, is_bot: false, first_name: "Test"},
        text: text
      }
    }
  end
end
```


For testing modules (for example, business logic modules) that just do calls with `ExGram`, you can skip setting up the bot and just use `ExGram.Test.expect/2` or similar.

```elixir
defmodule MyApp.NotificationsTest do
  use ExUnit.Case, async: true
  
  setup {ExGram.Test, :verify_on_exit!}

  test "sends notification message" do
    # Stub the API response
    ExGram.Test.expect(:send_message, fn body -> 
      # You can assert on body here
      assert body[:chat_id] == 123
      assert body[:text] == "Your order has shipped!"
      
      %{
        message_id: 1,
        chat: %{id: 123, type: "private"},
        date: 1_700_000_000,
        text: "Your order has shipped!"
      } 
    end)

    # Call your code
    {:ok, message} = ExGram.send_message(123, "Your order has shipped!")

    # Assert the result
    assert message.message_id == 1
    assert message.text == "Your order has shipped!"

    # If you prefer, you can check the calls after, but it's not needed with the :verify_on_exit!
    calls = ExGram.Test.get_calls()
    assert length(calls) == 1

    {verb, action, body} = hd(calls)
    assert verb == :post
    assert action == :send_message
    assert body[:chat_id] == 123
    assert body[:text] == "Your order has shipped!"
  end
end
```

## Expectations

Expectations are the **recommended approach** for testing. They are like stubs, but they are **consumed** after being called. Use them when you want to verify that a call happens exactly N times or to coordinate flows.

### Basic Expectations

```elixir
test "expects call exactly once" do
  ExGram.Test.expect(:send_message, %{
    message_id: 1,
    chat: %{id: 123},
    text: "Welcome!"
  })

  # First call - OK
  {:ok, _msg} = ExGram.send_message(123, "Welcome!")

  # Second call - Error! Expectation was already consumed
  {:error, %ExGram.Error{message: msg}} = ExGram.send_message(123, "Again")
  assert msg =~ "No stub or expectation"
end
```

### Expectations with Counts

Expect a call N times:

```elixir
test "expects call three times" do
  ExGram.Test.expect(:send_message, 3, %{
    message_id: 1,
    text: "ok"
  })

  ExGram.send_message(123, "First")
  ExGram.send_message(123, "Second")
  ExGram.send_message(123, "Third")

  # Fourth call fails
  {:error, _} = ExGram.send_message(123, "Fourth")
end
```

### Dynamic Expectations

Use callbacks with expectations too:

```elixir
test "expects specific request body" do
  ExGram.Test.expect(:send_message, fn body ->
    # Assertions inside the callback!
    assert body[:chat_id] == 123
    assert body[:text] =~ "order #"
    assert body[:parse_mode] == "HTML"

    {:ok, %{message_id: 1, text: body[:text]}}
  end)

  ExGram.send_message(123, "Your order #42 has shipped!", parse_mode: "HTML")
end
```

### Catch-All Expectations

Like catch-all stubs, but consumed after being called:

```elixir
test "catch-all expectation" do
  ExGram.Test.expect(2, fn action, body ->
    assert action in [:send_message, :send_chat_action]
    {:ok, true}
  end)

  ExGram.send_message(123, "Hello")      # Consumes 1/2
  ExGram.send_chat_action(123, "typing") # Consumes 2/2

  # Third call fails
  {:error, _} = ExGram.get_me()
end
```

### Error Responses

Return errors with `expect/2`:

```elixir
test "handles API errors" do
  error = %ExGram.Error{
    code: 400,
    message: "Bad Request: chat not found"
  }

  ExGram.Test.expect(:send_message, {:error, error})

  result = ExGram.send_message(123, "Hello")
  assert {:error, %ExGram.Error{message: "Bad Request: chat not found"}} = result
end
```

You can use it for in callbacks too:

```elixir
ExGram.Test.expect(:send_message, fn body ->
  if body[:chat_id] == 999 do
    {:error, %ExGram.Error{message: "Forbidden: bot was blocked by the user"}}
  else
    {:ok, %{message_id: 1, text: "ok"}}
  end
end)
```


## Stubbing Responses

Stubs are useful when you don't care about verifying the exact number of calls. They define responses for API calls and remain active for all matching calls until the test ends.

### Static Responses

The simplest stub returns a static value:

```elixir
test "static response" do
  # Returns {:ok, %{message_id: 1, ...}} for all /sendMessage calls
  ExGram.Test.stub(:send_message, %ExGram.Model.Message{
    message_id: 1,
    chat: %{id: 123, type: "private"},
    date: 1_700_000_000,
    text: "ok"
  })

  ExGram.send_message(123, "Hello")
  ExGram.send_message(456, "World")  # Same response

  calls = ExGram.Test.get_calls()
  assert length(calls) == 2
end
```

**Notice:** The adapter automatically wraps your response in `{:ok, value}`. Maps and structs are returned as-is. Booleans work too:

```elixir
ExGram.Test.stub(:pin_chat_message, true)
{:ok, true} = ExGram.pin_chat_message(123, 456)
```

### Dynamic Responses

Use a callback to assert on the body or compute responses based on the request body:

```elixir
test "dynamic response based on request" do
  ExGram.Test.stub(:send_message, fn body ->
    assert body[:text] in ["First", "Second"]
    
    # Echo back the text that was sent
    {:ok, %{
      message_id: System.unique_integer([:positive]),
      chat: %{id: body[:chat_id], type: "private"},
      date: 1_700_000_000,
      text: body[:text]
    }}
  end)

  {:ok, msg1} = ExGram.send_message(123, "First")
  {:ok, msg2} = ExGram.send_message(456, "Second")

  assert msg1.text == "First"
  assert msg2.text == "Second"
  assert msg1.chat.id == 123
  assert msg2.chat.id == 456
end
```

### Catch-All Stubs

Stub all API calls with a single callback that receives the action atom:

```elixir
test "catch-all stub" do
  ExGram.Test.stub(fn action, body ->
    case action do
      :send_message ->
        {:ok, %{message_id: 1, chat: %{id: body[:chat_id]}, text: "ok"}}

      :send_chat_action ->
        {:ok, true}

      :get_me ->
        {:ok, %{id: 1, is_bot: true, first_name: "TestBot"}}

      _ ->
        {:error, %ExGram.Error{message: "Unexpected call: #{action}"}}
    end
  end)

  {:ok, _msg} = ExGram.send_message(123, "Hello")
  {:ok, true} = ExGram.send_chat_action(123, "typing")
  {:ok, bot} = ExGram.get_me()

  assert bot.first_name == "TestBot"
end
```

**Notice:** Catch-all callbacks receive two arguments: `action` (atom like `:send_message`) and `body` (the request body map).

### Error Responses

Just like with `expect/2`, you can stub errors with `stub/2` in any of the two forms:

```elixir
test "handles API errors" do
  error = %ExGram.Error{
    code: 400,
    message: "Bad Request: chat not found"
  }

  ExGram.Test.stub(:send_message, {:error, error})

  result = ExGram.send_message(123, "Hello")
  assert {:error, %ExGram.Error{message: "Bad Request: chat not found"}} = result
  
  ExGram.Test.stub(:send_message, fn body ->
    if body[:chat_id] == 999 do
      {:error, %ExGram.Error{message: "Forbidden: bot was blocked by the user"}}
    else
      {:ok, %{message_id: 1, text: "ok"}}
    end
  end)

  result = ExGram.send_message(123, "Hello")
  assert {:error, %ExGram.Error{message: "Bad Request: chat not found"}} = result
end
```


## Priority Order

When a call is made, the adapter checks in this order:

1. **Path-specific expectations** (from `expect(:send_message, ...)`)
2. **Catch-all expectations** (from `expect(fn action, body -> ... end)`)
3. **Path-specific stubs** (from `stub(:send_message, ...)`)
4. **Catch-all stubs** (from `stub(fn action, body -> ... end)`)

This means expectations always take priority over stubs.

## Inspecting Calls

### get_calls/0

All API calls are recorded as tuples of `{verb, action, body}`:

```elixir
test "inspect recorded calls" do
  ExGram.Test.stub(:send_message, %{message_id: 1, text: "ok"})

  ExGram.send_message(123, "Hello", parse_mode: "HTML")
  ExGram.send_message(456, "World")

  calls = ExGram.Test.get_calls()
  assert length(calls) == 2

  # First call
  {verb, action, body} = Enum.at(calls, 0)
  assert verb == :post
  assert action == :send_message
  assert body[:chat_id] == 123
  assert body[:text] == "Hello"
  assert body[:parse_mode] == "HTML"

  # Second call
  {_verb, _action, body2} = Enum.at(calls, 1)
  assert body2[:chat_id] == 456
end
```

**Common patterns:**

```elixir
# Count calls to a specific action
calls = ExGram.Test.get_calls()
send_calls = Enum.filter(calls, fn {_, action, _} -> action == :send_message end)
assert length(send_calls) == 3

# Check if any call was made to an action
assert Enum.any?(calls, fn {_, action, _} -> action == :send_chat_action end)

# Extract body of first matching call
{_, _, body} = Enum.find(calls, fn {_, action, _} -> action == :edit_message_text end)
assert body[:message_id] == 123

# Assert no calls were made
assert ExGram.Test.get_calls() == []
```

### verify_on_exit!/1

Register an `on_exit` callback that automatically calls `verify!/0` after each test to check:

1. **No unexpected calls** - All calls must have a matching stub or expectation
2. **All expectations consumed** - All `expect/2,3` must be called the expected number of times

```elixir
defmodule MyApp.BotTest do
  use ExUnit.Case, async: true

  setup {ExGram.Test, :verify_on_exit!}

  test "sends welcome message" do
    ExGram.Test.expect(:send_message, %{message_id: 1, text: "Welcome"})

    MyApp.Bot.send_welcome(123)

    # No need to call verify! - happens automatically on test exit
  end
end
```

This is the recommended approach. Tests fail immediately if expectations aren't met or unexpected calls are made.

### verify!/0

Call `verify!/0` at any time to check:


```elixir
test "verify catches unfulfilled expectations" do
  ExGram.Test.expect(:send_message, %{message_id: 1, text: "ok"})

  # Forgot to call ExGram.send_message!

  assert_raise ExUnit.AssertionError, ~r/expected :send_message to be called 1 time/, fn ->
    ExGram.Test.verify!()
  end
end
```

```elixir
test "verify catches unexpected calls" do
  # No stub defined for :get_me
  {:error, _} = ExGram.get_me()  # Call is made but fails

  assert_raise ExUnit.AssertionError, ~r/unexpected calls.*:get_me/, fn ->
    ExGram.Test.verify!()
  end
end
```


## Async Tests and Process Isolation

### How It Works

The test adapter uses [NimbleOwnership](https://hexdocs.pm/nimble_ownership) to provide per-process isolation. Each test process that calls `stub/2` or `expect/2` becomes an "owner" of its own stubs, expectations, and call recordings.

This is why `async: true` works - each test has completely isolated state:

```elixir
defmodule MyApp.NotificationsTest do
  use ExUnit.Case, async: true  # Safe! Each test is isolated

  test "test A" do
    ExGram.Test.stub(:send_message, %{message_id: 1, text: "A"})
    {:ok, msg} = ExGram.send_message(123, "Test A")
    assert msg.text == "A"
  end

  test "test B" do
    ExGram.Test.stub(:send_message, %{message_id: 2, text: "B"})
    {:ok, msg} = ExGram.send_message(123, "Test B")
    assert msg.text == "B"  # Gets its own stub, not "A"
  end
end
```

### Sharing Stubs with Spawned Processes

When your code spawns a GenServer or Task that makes API calls, that process won't have access to your stubs by default. Use `allow/2` to share ownership:

```elixir
test "spawned process can use stubs" do
  ExGram.Test.stub(:send_message, %{message_id: 1, text: "ok"})

  test_pid = self()
  
  # Spawn a task that needs adapter access
  task = Task.async(fn ->
    # Allow the task to use this test's stubs
    ExGram.Test.allow(test_pid, self())
    
    ExGram.send_message(123, "From task")
  end)

  {:ok, msg} = Task.await(task)
  assert msg.message_id == 1
end
```

**Common pattern for GenServers:**

```elixir
defmodule MyApp.Worker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    # Allow worker to access test adapter if in test mode
    if owner = opts[:test_owner] do
      ExGram.Test.allow(owner, self())
    end

    {:ok, %{}}
  end

  # ... worker logic that calls ExGram
end

# In your test:
test "worker sends messages" do
  ExGram.Test.expect(:send_message, %{message_id: 1, text: "ok"})

  {:ok, worker} = MyApp.Worker.start_link(test_owner: self())

  # Worker can now use your stubs
end
```

### Global Mode

If you absolutely cannot use `async: true`, you can use global mode where all processes share one owner:

```elixir
defmodule MyApp.SyncTest do
  use ExUnit.Case, async: false  # Must be false

  setup {ExGram.Test, :set_global}

  test "uses global mode" do
    # All processes see the same stubs now
  end
end
```

Or, if you want to let ExGram.Test decide the correct mode `set_from_context` will use private on async tests and global on sync tests:

```elixir
setup {ExGram.Test, :set_from_context}
```

**Important:** Global mode is rarely needed. Use `allow/2` instead when possible.

## Testing a Bot

### Sending Updates

Use `ExGram.Test.push_update/2` to simulate incoming updates from Telegram.

By default, `ExGram.Test.start_bot/3` starts the bot with `handler_mode: :sync`. This means `push_update/2` is fully synchronous - when it returns, the bot's handler has already run to completion, including all API calls. You can assert on calls and results immediately after `push_update/2` returns, with no sleeps or polling needed.

```elixir
test "bot responds to /start command", context do
  # Start an isolated bot instance - defaults to handler_mode: :sync
  {bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot)

  # Set up the expectation before pushing the update
  ExGram.Test.expect(:send_message, fn body -> 
    assert body[:text] =~ "Welcome"
    
   %{
     message_id: 1,
     chat: %{id: 123, type: "private"},
     text: "Welcome to MyBot!"
   }
  end)

  # Build an update
  update = %ExGram.Model.Update{
    update_id: 1,
    message: %ExGram.Model.Message{
      message_id: 100,
      date: 1_700_000_000,
      chat: %ExGram.Model.Chat{id: 123, type: "private"},
      from: %ExGram.Model.User{id: 123, is_bot: false, first_name: "Test"},
      text: "/start"
    }
  }

  # Push the update - returns only after the handler has fully executed
  ExGram.Test.push_update(bot_name, update)
  # At this point the :send_message expectation has already been consumed
end
```

**Notice:** `push_update/2` automatically calls `allow/2` for you, so the bot process has access to your stubs.

### Handler Mode

The `handler_mode` option controls how the dispatcher executes your bot's handler:

- `:sync` - The handler runs inline within the dispatcher's process. `push_update/2` blocks until the handler and all its API calls complete. **This is the default when using `ExGram.Test.start_bot/3`.**
- `:async` - The handler is spawned in a separate process. `push_update/2` returns immediately after the update is enqueued. This is the default in production.

You can override the mode when starting a bot:

```elixir
# Force async mode (the production default) in a test
{bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot, handler_mode: :async)
```

### Building Model Structs

Helper functions make building test data easier:

```elixir
defmodule MyApp.TestHelpers do
  def build_message(attrs \\ %{}) do
    defaults = %{
      message_id: System.unique_integer([:positive]),
      date: 1_700_000_000,
      chat: %{id: 123, type: "private"},
      from: %{id: 123, is_bot: false, first_name: "Test"},
      text: "Hello"
    }

    cast(defaults, attrs, ExGram.Model.Message)
  end

  def build_update(attrs \\ %{}) do
    defaults = %{
      update_id: System.unique_integer([:positive]),
      message: build_message()
    }

    cast(defaults, attrs, ExGram.Model.Update)
  end

  def build_callback_query(attrs \\ %{}) do
    defaults = %{
      id: "cbq-#{System.unique_integer([:positive])}",
      from: %{id: 123, is_bot: false, first_name: "Test"},
      message: build_message(),
      data: "button_action"
    }

    cast(defaults, attrs, ExGram.Model.CallbackQuery)
  end
  
  defp cast(defaults, attrs, type) do
   defaults
   |> Map.merge(Map.new(attrs))
   |> ExGram.Cast.cast(type)
  end
end

# In tests:
import MyApp.TestHelpers

test "handles callback query" do
  query = build_callback_query(data: "approve:order-123")
  update = build_update(callback_query: query)

  ExGram.Test.expect(:answer_callback_query, true)
  ExGram.Test.push_update(:my_bot, update)

  # ...
end
```

### Full Bot Test Example

Here's a complete example showing bot testing, with isolated bots started on every test with commands and callbacks:

```elixir
defmodule MyApp.BotTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.{Update, Message, User, Chat, CallbackQuery}

  setup {ExGram.Test, :verify_on_exit!}

  # Each test starts its own isolated bot instance with handler_mode: :sync (the default).
  # push_update/2 blocks until the handler has fully run, so no sleeps or polling needed.
  setup context do
    {bot_name, _} = ExGram.Test.start_bot(context, MyApp.Bot)

    {:ok, bot_name: bot_name}
  end


  describe "commands" do
    test "responds to /start", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:chat_id] == 123
        assert body[:text] =~ "Welcome"

        {:ok, %{message_id: 1, chat: %{id: 123}, text: body[:text]}}
      end)

      update = %Update{
        update_id: 1,
        message: %Message{
          message_id: 100,
          date: 1_700_000_000,
          chat: %Chat{id: 123, type: "private"},
          from: %User{id: 123, is_bot: false, first_name: "Alice"},
          text: "/start"
        }
      }

      # Returns only after the handler has completed - expectation is already consumed
      ExGram.Test.push_update(bot_name, update)
    end

    test "responds to /help with keyboard", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:reply_markup] 
        assert markup = body[:reply_markup]
        assert is_list(markup[:inline_keyboard])

        {:ok, %{message_id: 2, chat: %{id: 123}, text: "Help menu"}}
      end)

      update = %Update{
        update_id: 2,
        message: %Message{
          message_id: 101,
          date: 1_700_000_000,
          chat: %Chat{id: 123, type: "private"},
          from: %User{id: 123, is_bot: false, first_name: "Alice"},
          text: "/help"
        }
      }

      ExGram.Test.push_update(bot_name, update)
    end
  end

  describe "callback queries" do
    test "handles button press", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_callback_query, true)
      ExGram.Test.expect(:send_message, fn body -> 
        assert body[:text] == "Action completed"
        {:ok, %{message_id: 3, text: "Action completed"}}
      end)

      update = %Update{
        update_id: 3,
        callback_query: %CallbackQuery{
          id: "cbq-1",
          from: %User{id: 123, is_bot: false, first_name: "Alice"},
          message: %Message{
            message_id: 100,
            date: 1_700_000_000,
            chat: %Chat{id: 123, type: "private"}
          },
          data: "action:approve"
        }
      }

      ExGram.Test.push_update(bot_name, update)
    end
  end
end
```

### Testing the initial calls

Up until now, we skipped the initial `get_me` call and the set commands calls, they are executed on bot's startup, so it's cumbersome to setup it up in every test.

I recommend to not bother testing this, but if you want to test it anyway, this is how you do it:

(You can also find a working test like this in `test/ex_gram/bot_test.exs` called `"Register commands on startup"`)

- First, in your bot's `init/1` callback, you have to notify the test that you are starting, so the test can allow the bot's PID to use the mocks, and it has to wait:

```elixir
# lib/my_app/bot.ex
defmodule MyApp.Bot do
  use ExGram.Bot, name: :my_bot
  
  # .....
  
  def init(opts) do
    if opts[:extra_info][:test_init] do
        test_pid = opts[:extra_info][:test_pid]
        send(test_pid, :init)
        
        receive do
            :continue -> :ok
        end
    end
  end
  
  # .....
end
```

- Then, in your test, you need to start the bot passing that extra information, waiting for the `:init` and allowing the process:

```elixir
# test/my_app/bot_test.exs

test "Register commands on startup", context do
  test_pid = self()

  ExGram.Test.expect(:get_me, build_user(%{id: 999, is_bot: true, first_name: "TestBot", username: "test_bot"}))

  ExGram.Test.expect(:set_my_commands, fn body ->
    assert body[:scope] == %{type: "default"}
    assert length(body[:commands]) == 2
    assert Enum.any?(body[:commands], fn cmd -> cmd[:command] == "start" end)
    assert Enum.any?(body[:commands], fn cmd -> cmd[:command] == "help" end)

    {:ok, true}
  end)

  # There can be more than one command depending on the scopes/languages
  ExGram.Test.expect(:set_my_commands, fn body ->
    assert body[:scope] == %{type: "default"}
    assert body[:language_code] == "es"
    assert length(body[:commands]) == 2
    assert Enum.any?(body[:commands], fn cmd -> cmd[:command] == "start" end)
    assert Enum.any?(body[:commands], fn cmd -> cmd[:command] == "ayuda" end)

    # Final message to the test, to know we are done with the initialization
    send(test_pid, :commands_set)
    {:ok, true}
  end)

  # Important here! We send `username: nil` to do the initial `get_me` and `setup_commands: true` to setup on start
  # We also use the extra_info to pass :test_init, so the bot knows it has to do the test workflow
  # The test_pid is already injected by the `ExGram.Test.start_bot/3` method
  bot_opts = [username: nil, setup_commands: true, extra_info: %{test_init: true}]
  {bot_name, _} = ExGram.Test.start_bot(context, SetupCommandBot, bot_opts)

  # Allow the bot to access the `ExGram.Test` mocks
  # In normal tests you don't need this, because when you do a `ExGram.Test.push_update/2`
  # it's done automatically, but since this is on startup we have to manually allow it
  
  allow_dispatcher(bot_name)
  
  # Let the initialization continue
  send(Process.whereis(bot_name), :continue)

  # We now finished the initialization with the last set commands
  assert_receive :commands_set, 1000
  
  # Now the bot is fully initialize!
end

defp allow_dispatcher(bot_name) do
    receive do
      :init ->
        if pid = Process.whereis(bot_name) do
          ExGram.Test.allow(self(), pid)
        end
    end
end
```


## Next Steps

- [Handling Updates](handling-updates.md) - Learn how to structure your bot's command and callback handlers
- [Sending Messages](sending-messages.md) - Master all the ways to send messages, keyboards, and media
- [Middlewares](middlewares.md) - Add authentication, logging, and other cross-cutting concerns to your bot
