defmodule ExGram.Test do
  @moduledoc """
  ExGram testing conveniences.

  This module provides a unified interface for all testing utilities, delegating to
  `ExGram.Adapter.Test` and `ExGram.Updates.Test`.

  ## Overview

  ExGram ships with a test adapter that intercepts Telegram API calls, making it easy
  to test bots without hitting real servers. The adapter supports per-process isolation
  for async tests and provides stub/expect/verify semantics similar to [Mox](https://hexdocs.pm/mox).

  ## Quick Start

  Configure your test environment in `config/test.exs`:

      config :ex_gram,
        token: "test_token",
        adapter: ExGram.Adapter.Test,
        updates: ExGram.Updates.Test

  Start the adapter in `test_helper.exs`:

      {:ok, _} = ExGram.Adapter.Test.start_link()
      ExUnit.start()

  Use the testing conveniences from this module in your tests:

      defmodule MyBotTest do
        use ExUnit.Case, async: true
        import ExGram.Test, only: [verify_on_exit!: 1]

        setup :verify_on_exit!

        test "sends welcome message" do
          ExGram.Test.stub(:send_message, %{message_id: 1, text: "Welcome!"})

          MyBot.send_welcome(123)

          calls = ExGram.Test.get_calls()
          assert length(calls) == 1
        end
      end

  ## Stubbing

  Stubs define responses that persist for all matching calls:

      # Static response
      ExGram.Test.stub(:send_message, %{message_id: 1, text: "ok"})

      # Dynamic response based on request body
      ExGram.Test.stub(:send_message, fn body ->
        {:ok, %{message_id: 1, chat_id: body["chat_id"], text: "ok"}}
      end)

      # Catch-all for all actions
      ExGram.Test.stub(fn action, body ->
        case action do
          :send_message -> {:ok, %{message_id: 1, text: "ok"}}
          :get_me -> {:ok, %{id: 1, is_bot: true}}
        end
      end)

  ## Expectations

  Expectations are consumed after being called and can be verified:

      # Consumed after 1 call
      ExGram.Test.expect(:send_message, %{message_id: 1, text: "ok"})

      # Consumed after N calls
      ExGram.Test.expect(:send_message, 3, %{message_id: 1, text: "ok"})

      # Verify all expectations were met
      ExGram.Test.verify!()

  ## Testing Bots

  Push updates to your bot using `push_update/2`:

      update = %ExGram.Model.Update{
        update_id: 1,
        message: %ExGram.Model.Message{
          message_id: 100,
          chat: %ExGram.Model.Chat{id: 123, type: "private"},
          text: "/start"
        }
      }

      ExGram.Test.push_update(:my_bot, update)

  See the [Testing guide](testing.md) for more examples and patterns.
  """

  # ---------------------------------------------------------------------------
  # Stub functions
  # ---------------------------------------------------------------------------

  alias ExGram.Adapter.Test

  def start_bot(context, bot_module, opts \\ []) do
    base = context.test |> Atom.to_string() |> String.replace(~r/[^a-z0-9]/i, "_")
    bot_name = String.to_atom("test_bot_#{base}_#{System.unique_integer([:positive])}")
    module_name = Module.concat([bot_module, String.to_atom("Bot_#{bot_name}")])
    extra_info = opts |> Keyword.get(:extra_info, %{}) |> Map.put(:test_pid, self())

    base_opts = [
      method: :test,
      name: module_name,
      bot_name: bot_name,
      token: "test_token",
      username: "test_bot",
      setup_commands: false,
      extra_info: extra_info
    ]

    bot_opts = Keyword.merge(base_opts, opts)

    {:ok, _pid} =
      bot_module.start_link(bot_opts)

    {bot_name, module_name}
  end

  @doc """
  Stub a response for a specific action or path.

  The response can be a static value (wrapped in `{:ok, value}`) or a callback
  that receives the request body.

  ## Examples

      ExGram.Test.stub(:send_message, %{message_id: 1, text: "ok"})

      ExGram.Test.stub(:send_message, fn body ->
        {:ok, %{message_id: 1, chat_id: body["chat_id"], text: "ok"}}
      end)

  """
  def stub(action, response) when is_atom(action) or is_binary(action) do
    Test.stub(action, response)
  end

  @doc """
  Stub a catch-all response with a callback that receives action and body.

  ## Example

      ExGram.Test.stub(fn action, body ->
        case action do
          :send_message -> {:ok, %{message_id: 1, text: "ok"}}
          :get_me -> {:ok, %{id: 1, is_bot: true}}
        end
      end)

  """
  def stub(callback) when is_function(callback, 2) do
    Test.stub(callback)
  end

  @doc """
  Stub an error response for a specific action.

  ## Example

      error = %ExGram.Error{code: 400, message: "Bad Request"}
      ExGram.Test.stub_error(:send_message, error)

  """
  defdelegate stub_error(action, error), to: Test

  # ---------------------------------------------------------------------------
  # Expect functions
  # ---------------------------------------------------------------------------

  @doc """
  Expect a catch-all response with a callback, consumed after 1 call.

  ## Example

      ExGram.Test.expect(fn action, body ->
        assert action == :send_message
        {:ok, %{message_id: 1, text: "ok"}}
      end)

  """
  def expect(callback) when is_function(callback, 2) do
    Test.expect(1, callback)
  end

  @doc """
  Expect a response for a specific action, consumed after 1 call.

  ## Examples

      ExGram.Test.expect(:send_message, %{message_id: 1, text: "ok"})

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Hello"
        {:ok, %{message_id: 1, text: "ok"}}
      end)

  """
  def expect(action, response) when is_atom(action) or is_binary(action) do
    Test.expect(action, 1, response)
  end

  # Catch-all with count (no separate doc - covered by arity-1 catch-all above)
  def expect(n, callback) when is_integer(n) and n > 0 and is_function(callback, 2) do
    Test.expect(n, callback)
  end

  @doc """
  Expect a response for a specific action, consumed after N calls.

  ## Example

      ExGram.Test.expect(:send_message, 3, %{message_id: 1, text: "ok"})

  """
  def expect(action, n, response) when (is_atom(action) or is_binary(action)) and is_integer(n) and n > 0 do
    Test.expect(action, n, response)
  end

  # ---------------------------------------------------------------------------
  # Introspection functions
  # ---------------------------------------------------------------------------

  @doc """
  Get all recorded API calls as a list of `{verb, action, body}` tuples.

  ## Example

      calls = ExGram.Test.get_calls()
      assert length(calls) == 2

      {verb, action, body} = hd(calls)
      assert verb == :post
      assert action == :send_message
      assert body["chat_id"] == 123

  """
  defdelegate get_calls(), to: Test

  @doc """
  Verify that all expectations have been met and no unexpected calls were made.

  Raises an `ExUnit.AssertionError` if:
  - Any expectations remain unfulfilled
  - Any unexpected calls were made (calls without a stub or expectation)

  ## Example

      ExGram.Test.expect(:send_message, %{message_id: 1, text: "ok"})
      ExGram.send_message(123, "Hello")
      ExGram.Test.verify!()  # Passes

  """
  defdelegate verify!(), to: Test

  @doc """
  Verify expectations for a specific process.

  ## Example

      ExGram.Test.verify!(pid)

  """
  defdelegate verify!(pid), to: Test

  @doc """
  Register an ExUnit callback that automatically verifies expectations on test exit.

  Use this in your test setup for automatic verification:

  ## Example

      defmodule MyBotTest do
        use ExUnit.Case, async: true
        import ExGram.Test, only: [verify_on_exit!: 1]

        setup :verify_on_exit!

        test "my test" do
          ExGram.Test.expect(:send_message, %{message_id: 1})
          # Test code...
        end
      end

  """
  defdelegate verify_on_exit!(context), to: Test

  # ---------------------------------------------------------------------------
  # Process isolation functions
  # ---------------------------------------------------------------------------

  @doc """
  Allow a spawned process to access the current test's stubs and expectations.

  ## Example

      test "spawned process can use stubs" do
        ExGram.Test.stub(:send_message, %{message_id: 1, text: "ok"})

        task = Task.async(fn ->
          ExGram.send_message(123, "From task")
        end)

        ExGram.Test.allow(self(), task.pid)

        {:ok, msg} = Task.await(task)
        assert msg.message_id == 1
      end

  """
  defdelegate allow(owner_pid, allowed_pid), to: Test

  @doc """
  Set the adapter to global mode (shared stubs across all processes).

  Only use this for synchronous tests. Prefer `allow/2` for async tests.

  ## Example

      setup do
        ExGram.Test.set_global()
        on_exit(fn -> ExGram.Test.set_private() end)
      end

  """
  defdelegate set_global(), to: Test

  @doc """
  Set the adapter to private mode (per-process isolation).

  This is the default mode.
  """
  defdelegate set_private(), to: Test

  @doc """
  Set the adapter to private or global mode depending on the current test context.
  """
  defdelegate set_from_context(context), to: Test

  @doc """
  Clean the current process's stubs, expectations, and recorded calls.

  Useful in setup blocks if you need to reset state:

  ## Example

      setup do
        ExGram.Test.clean()
        :ok
      end

  """
  defdelegate clean(), to: Test

  # ---------------------------------------------------------------------------
  # Update testing functions
  # ---------------------------------------------------------------------------

  @doc """
  Push a test update to a bot's dispatcher.

  This simulates an incoming update from Telegram and automatically allows
  the bot process to access your test's stubs.

  ## Example

      test "bot responds to /start" do
        ExGram.Test.stub(:send_message, %{message_id: 1, text: "Welcome!"})

        update = %ExGram.Model.Update{
          update_id: 1,
          message: %ExGram.Model.Message{
            message_id: 100,
            date: 1_700_000_000,
            chat: %ExGram.Model.Chat{id: 123, type: "private"},
            text: "/start"
          }
        }

        ExGram.Test.push_update(:my_bot, update)

        calls = ExGram.Test.get_calls()
        assert length(calls) == 1
      end

  """
  defdelegate push_update(bot_name, update), to: ExGram.Updates.Test
end
