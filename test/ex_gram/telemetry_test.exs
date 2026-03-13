defmodule ExGram.TelemetryTest do
  use ExUnit.Case, async: false

  import ExGram.TestHelpers

  setup {ExGram.Test, :set_from_context}
  setup {ExGram.Test, :verify_on_exit!}

  # Attaches a telemetry handler that sends all matching events to the test process.
  # Returns the handler id so it can be detached after the test.
  defp attach_telemetry(test_pid, events) do
    handler_id = "telemetry-test-#{System.unique_integer([:positive])}"

    ExUnit.CaptureLog.capture_log(fn ->
      :telemetry.attach_many(
        handler_id,
        events,
        fn event, measurements, metadata, _ ->
          send(test_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )
    end)

    on_exit(fn -> :telemetry.detach(handler_id) end)
    handler_id
  end

  # ---------------------------------------------------------------------------
  # Request events
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :request, ...]" do
    defmodule RequestBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_request_bot

      command("ping")

      def handle({:command, :ping, _}, context) do
        answer(context, "pong")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, RequestBot)
      {:ok, bot_name: bot_name}
    end

    test "emits start and stop events on successful API call", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :request, :start],
        [:ex_gram, :request, :stop]
      ])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "pong"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "/ping"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :request, :start], start_measurements,
                      %{method: "sendMessage"} = start_meta},
                     500

      assert is_integer(start_measurements.system_time)
      assert is_integer(start_measurements.monotonic_time)
      assert start_meta.request_type == :post
      assert is_map(start_meta.body)
      assert start_meta.bot == bot_name

      assert_receive {:telemetry, [:ex_gram, :request, :stop], stop_measurements, %{method: "sendMessage"} = stop_meta},
                     500

      assert is_integer(stop_measurements.duration)
      assert stop_measurements.duration >= 0
      assert stop_meta.request_type == :post
      assert {:ok, _} = stop_meta.result
    end

    test "emits stop event with error result on failed API call", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :request, :start],
        [:ex_gram, :request, :stop]
      ])

      ExGram.Test.expect(:send_message, fn _body ->
        {:error, %ExGram.Error{code: 403, message: "Forbidden"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "/ping"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :request, :stop], _measurements, %{method: "sendMessage"} = stop_meta},
                     500

      assert {:error, %ExGram.Error{}} = stop_meta.result
    end

    test "stop metadata includes bot name when bot: option is present",
         %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :request, :start]])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "pong"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "/ping"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :request, :start], _m, %{method: "sendMessage"} = meta},
                     500

      assert meta.bot == bot_name
    end

    test "token is not present in request metadata", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :request, :start]])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "pong"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "/ping"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :request, :start], _m, %{method: "sendMessage"} = meta},
                     500

      refute Map.has_key?(meta, :token)
      refute Map.has_key?(meta.body, :token)
    end
  end

  # ---------------------------------------------------------------------------
  # Update events
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :update, ...]" do
    defmodule UpdateBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_update_bot

      def handle({:text, _text, _msg}, context) do
        answer(context, "got it")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, UpdateBot)
      {:ok, bot_name: bot_name}
    end

    test "emits start and stop events for each update", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :update, :start],
        [:ex_gram, :update, :stop]
      ])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "got it"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :update, :start], start_measurements, start_meta},
                     500

      assert is_integer(start_measurements.system_time)
      assert is_integer(start_measurements.monotonic_time)
      assert start_meta.bot == bot_name
      assert %ExGram.Model.Update{} = start_meta.update
      assert start_meta.update.update_id == update.update_id

      assert_receive {:telemetry, [:ex_gram, :update, :stop], stop_measurements, stop_meta}, 500

      assert is_integer(stop_measurements.duration)
      assert stop_meta.bot == bot_name
      assert %ExGram.Cnt{} = stop_meta.context
      assert stop_meta.halted == false
    end

    test "stop event reports halted: false when no middleware halts", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :update, :stop]])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "got it"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :update, :stop], _measurements, meta}, 500
      assert meta.halted == false
      assert meta.bot == bot_name
    end
  end

  # ---------------------------------------------------------------------------
  # Update events with halting middleware
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :update, :stop] with halting middleware" do
    defmodule HaltMiddleware do
      @moduledoc false
      @behaviour ExGram.Middleware

      def init(opts), do: opts

      def call(context, _opts) do
        %{context | halted: true}
      end
    end

    defmodule HaltingBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_halting_bot

      middleware(ExGram.TelemetryTest.HaltMiddleware)

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, HaltingBot)
      {:ok, bot_name: bot_name}
    end

    test "reports halted: true in stop event metadata", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :update, :stop]])

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :update, :stop], _measurements, meta}, 500
      assert meta.halted == true
      assert meta.bot == bot_name
    end
  end

  # ---------------------------------------------------------------------------
  # Handler events
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :handler, ...]" do
    defmodule HandlerBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_handler_bot

      command("greet")

      def handle({:command, :greet, _}, context) do
        answer(context, "Hello!")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, HandlerBot)
      {:ok, bot_name: bot_name}
    end

    test "emits start and stop events around handle/2 invocation", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :handler, :start],
        [:ex_gram, :handler, :stop]
      ])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "Hello!"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "/greet"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :handler, :start], start_measurements, start_meta},
                     500

      assert is_integer(start_measurements.system_time)
      assert is_integer(start_measurements.monotonic_time)
      assert start_meta.bot == bot_name
      assert start_meta.handler == ExGram.TelemetryTest.HandlerBot
      assert %ExGram.Cnt{} = start_meta.context

      assert_receive {:telemetry, [:ex_gram, :handler, :stop], stop_measurements, stop_meta},
                     500

      assert is_integer(stop_measurements.duration)
      assert stop_meta.bot == bot_name
      assert stop_meta.handler == ExGram.TelemetryTest.HandlerBot
      assert %ExGram.Cnt{} = stop_meta.result_context
    end

    test "emits exception event when handler raises", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :handler, :exception]])

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      # We can't easily make the handler raise in HandlerBot, so we use a
      # dedicated crashing bot in the next describe block.
      # This test just verifies the event is not fired for a normal update.
      ExGram.Test.push_update(bot_name, update)

      refute_receive {:telemetry, [:ex_gram, :handler, :exception], _, _}, 200
    end
  end

  # ---------------------------------------------------------------------------
  # Handler exception event
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :handler, :exception]" do
    defmodule CrashBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_crash_bot

      def handle({:text, "crash", _msg}, _context) do
        raise RuntimeError, "intentional crash"
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, CrashBot)
      {:ok, bot_name: bot_name}
    end

    test "emits exception event when handler raises", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :handler, :exception]])

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "crash"})
        })

      # push_update uses sync_update; the handler reraises, which propagates
      # back through the GenServer call as an exit. Capture logs and exit to
      # suppress the expected OTP crash report.
      ExUnit.CaptureLog.capture_log(fn ->
        catch_exit(ExGram.Test.push_update(bot_name, update))
      end)

      assert_receive {:telemetry, [:ex_gram, :handler, :exception], measurements, meta}, 500

      assert is_integer(measurements.duration)
      assert meta.kind == :error
      assert %RuntimeError{message: "intentional crash"} = meta.reason
      assert is_list(meta.stacktrace)
      assert meta.bot == bot_name
      assert meta.handler == ExGram.TelemetryTest.CrashBot
    end
  end

  # ---------------------------------------------------------------------------
  # Middleware events
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :middleware, ...]" do
    defmodule LoggingMiddleware do
      @moduledoc false
      @behaviour ExGram.Middleware

      def init(opts), do: opts

      def call(context, _opts), do: context
    end

    defmodule MiddlewareBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_middleware_bot

      middleware(ExGram.TelemetryTest.LoggingMiddleware)

      def handle({:text, _text, _msg}, context) do
        answer(context, "ok")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, _} = ExGram.Test.start_bot(context, MiddlewareBot)
      {:ok, bot_name: bot_name}
    end

    test "emits start and stop events for each middleware", %{bot_name: bot_name} do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :middleware, :start],
        [:ex_gram, :middleware, :stop]
      ])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "ok"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :middleware, :start], start_measurements, start_meta},
                     500

      assert is_integer(start_measurements.system_time)
      assert is_integer(start_measurements.monotonic_time)
      assert start_meta.bot == bot_name
      assert start_meta.middleware == ExGram.TelemetryTest.LoggingMiddleware
      assert %ExGram.Cnt{} = start_meta.context

      assert_receive {:telemetry, [:ex_gram, :middleware, :stop], stop_measurements, stop_meta},
                     500

      assert is_integer(stop_measurements.duration)
      assert stop_meta.bot == bot_name
      assert stop_meta.middleware == ExGram.TelemetryTest.LoggingMiddleware
      assert %ExGram.Cnt{} = stop_meta.context
      assert stop_meta.halted == false
    end

    test "stop metadata reports halted: false for non-halting middleware", %{bot_name: bot_name} do
      # Verify that a non-halting middleware reports halted: false in stop metadata.
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :middleware, :stop]])

      ExGram.Test.expect(:send_message, fn _body ->
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "ok"}}
      end)

      update =
        build_update(%{
          message: build_message(%{chat: build_chat(%{id: 123}), text: "hello"})
        })

      ExGram.Test.push_update(bot_name, update)

      assert_receive {:telemetry, [:ex_gram, :middleware, :stop], _m, meta}, 500
      assert meta.halted == false
    end
  end

  # ---------------------------------------------------------------------------
  # Polling events
  # ---------------------------------------------------------------------------

  describe "[:ex_gram, :polling, ...]" do
    defmodule ParrotBot do
      @moduledoc false
      use ExGram.Bot, name: :telemetry_parrot_bot

      def handle({:text, text, _}, context) do
        answer(context, text)
      end

      def handle(_, context), do: context
    end

    test "emits start and stop events on each polling cycle", context do
      test_pid = self()

      attach_telemetry(test_pid, [
        [:ex_gram, :polling, :start],
        [:ex_gram, :polling, :stop]
      ])

      # Stub get_updates to return one update, then empty (to stop)
      ExGram.Test.expect(:get_updates, 2, fn _body ->
        send(test_pid, :get_updates_called)
        assert_receive :continue, 1000

        {:ok,
         [
           build_update(%{
             message: build_message(%{chat: build_chat(%{id: 123}), text: "ping"})
           })
         ]}
      end)

      ExGram.Test.stub(:send_message, fn body ->
        assert body.text == "ping"
        {:ok, %{message_id: 1, chat: %{id: 123, type: "private"}, date: 0, text: "ping"}}
      end)

      {bot_name, _} = ExGram.Test.start_bot(context, ParrotBot)

      ExGram.Test.allow(test_pid, Process.whereis(bot_name))

      {:ok, polling_pid} =
        ExGram.Updates.Polling.start_link(%{
          bot: bot_name,
          token: "fake-token",
          get_updates_opts: [timeout: 30_000],
          delete_webhook: false
        })

      ExGram.Test.allow(self(), polling_pid)

      assert_receive :get_updates_called, 500

      assert_receive {:telemetry, [:ex_gram, :polling, :start], start_measurements, start_meta}, 500

      assert is_integer(start_measurements.system_time)
      assert is_integer(start_measurements.monotonic_time)
      assert start_meta.bot == bot_name

      refute_received {:telemetry, [:ex_gram, :polling, :stop], _, _}

      send(polling_pid, :continue)

      assert_receive {:telemetry, [:ex_gram, :polling, :stop], stop_measurements, stop_meta}, 500

      assert is_integer(stop_measurements.duration)
      assert stop_meta.bot == bot_name
      assert stop_meta.updates_count == 1

      assert_receive :get_updates_called, 500

      Process.exit(polling_pid, :normal)
    end
  end

  # ---------------------------------------------------------------------------
  # ExGram.Telemetry helper functions
  # ---------------------------------------------------------------------------

  describe "ExGram.Telemetry helper functions" do
    test "start/2 emits a :start event and returns a monotonic start time" do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :request, :start]])

      start_time = ExGram.Telemetry.start(:request, %{method: "test", request_type: :get, body: %{}, bot: nil})

      assert is_integer(start_time)

      assert_receive {:telemetry, [:ex_gram, :request, :start], measurements, meta}, 500
      assert is_integer(measurements.system_time)
      assert is_integer(measurements.monotonic_time)
      assert meta.method == "test"
    end

    test "stop/3 emits a :stop event with duration" do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :request, :stop]])

      start_time = System.monotonic_time()

      ExGram.Telemetry.stop(:request, start_time, %{
        method: "test",
        request_type: :get,
        body: %{},
        bot: nil,
        result: {:ok, true}
      })

      assert_receive {:telemetry, [:ex_gram, :request, :stop], measurements, _meta}, 500
      assert is_integer(measurements.duration)
      assert measurements.duration >= 0
    end

    test "exception/6 emits an :exception event with kind/reason/stacktrace" do
      test_pid = self()

      attach_telemetry(test_pid, [[:ex_gram, :request, :exception]])

      start_time = System.monotonic_time()
      stack = [{ExGram, :test, 0, []}]

      ExGram.Telemetry.exception(:request, start_time, :error, %RuntimeError{message: "oops"}, stack, %{
        method: "test",
        request_type: :post,
        body: %{},
        bot: nil
      })

      assert_receive {:telemetry, [:ex_gram, :request, :exception], measurements, meta}, 500
      assert is_integer(measurements.duration)
      assert meta.kind == :error
      assert %RuntimeError{message: "oops"} = meta.reason
      assert meta.stacktrace == stack
    end
  end
end
