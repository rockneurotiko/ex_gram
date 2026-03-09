defmodule ExGram.Adapter.Test do
  @moduledoc """
  HTTP Adapter for testing with per-process isolation using NimbleOwnership.

  Supports both private mode (per-process stubs for async tests) and global mode
  (shared stubs for synchronous tests).

  ## Usage

      # In test_helper.exs or application
      ExGram.Adapter.Test.start_link()

      # In your test
      setup {ExGram.Test, :verify_on_exit!}

      test "my test" do
        ExGram.Adapter.Test.stub(:get_me, %{id: 123, is_bot: true})
        ExGram.Adapter.Test.expect(:send_message, fn body ->
          assert body[:text] == "value"
          {:ok, %{message_id: 1}}
        end)

        # Make API calls
        ExGram.send_message(123, "Hello")

        # You can get the calls if you want
        calls = ExGram.Adapter.Test.get_calls()
        # calls = [{:post, :send_message, %{"chat_id" => 123, ...}}]
      end

  You can learn mode in the [testing guide](https://hexdocs.pm/ex_gram/testing.html)

  ## API Methods

  All stub and expect functions accept action atoms (`:send_message`) that match the names of the
  ExGram functions (ExGram.get_me -> :get_me)
  """

  @behaviour ExGram.Adapter

  @timeout 30_000
  @ownership_key :ex_gram_adapter_test
  @ownership_server ExGram.Adapter.Test.Ownership

  # Metadata structure per owner
  defstruct responses: %{},
            errors: %{},
            expectations: %{},
            calls: [],
            catch_all_stub: nil,
            catch_all_expectations: [],
            unexpected_calls: []

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Start the ownership server. Should be called once in test_helper or application.
  """
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @ownership_server)
    NimbleOwnership.start_link(opts)
  end

  @doc """
  Child spec for supervision tree.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Stub a catch-all response with a callback that receives action atom and body.
  This will be used for any path that doesn't have a specific stub.
  Owned by the calling process.

  ## Example

      stub(fn action, body ->
        case action do
          :send_message -> {:ok, %ExGram.Model.Message{...}}
          :send_chat_action -> {:ok, true}
        end
      end)

  """
  def stub(callback) when is_function(callback, 2) do
    update_owner_metadata(fn meta ->
      %{meta | catch_all_stub: callback}
    end)

    :ok
  end

  @doc """
  Stub a response for a Telegram API path or action atom. Always returns this response.
  Owned by the calling process.

  The response can be:
  - A static value (will be wrapped in `{:ok, value}` if not already a tuple)
  - An arity-1 function that receives the request body
  - An arity-2 function that receives path and body (use `stub/1` instead for catch-all)

  ## Examples

      # Static response with atom
      stub(:send_message, %ExGram.Model.Message{...})

      # Dynamic response based on body
      stub(:send_message, fn body ->
        assert body["text"] =~ "Hello"
        {:ok, %ExGram.Model.Message{...}}
      end)

  """
  def stub(action, response) do
    update_owner_metadata(fn meta ->
      %{meta | responses: Map.put(meta.responses, action, response)}
    end)

    :ok
  end

  @doc """
  Stub an error for a Telegram API path or action atom. Always returns this error.
  Owned by the calling process.
  """
  def stub_error(action, error) do
    update_owner_metadata(fn meta ->
      %{meta | errors: Map.put(meta.errors, action, error)}
    end)

    :ok
  end

  @doc """
  Expect a catch-all response with a callback that receives action atom and body.
  Consumed after the first call (n=1).

  ## Example

      expect(fn action, body ->
        assert action == :send_message
        {:ok, %ExGram.Model.Message{...}}
      end)

  """
  def expect(callback) when is_function(callback, 2) do
    expect(1, callback)
  end

  @doc """
  Expect a catch-all response with a callback that receives action atom and body.
  Consumed after n calls.

  ## Example

      expect(2, fn action, body ->
        {:ok, %ExGram.Model.Message{...}}
      end)

  """
  def expect(n, callback) when is_integer(n) and n > 0 and is_function(callback, 2) do
    update_owner_metadata(fn meta ->
      %{meta | catch_all_expectations: meta.catch_all_expectations ++ [{callback, n}]}
    end)

    :ok
  end

  @doc """
  Expect a response for a path or action atom. Consumed after n calls, then removed.
  Expectations are checked before stubs.

  The response can be:
  - A static value (will be wrapped in `{:ok, value}` if not already a tuple)
  - An arity-1 function that receives the request body

  ## Examples

      # Static response with atom, default n=1
      expect(:send_message, %ExGram.Model.Message{...})

      # Static response with count
      expect(:send_message, 2, %ExGram.Model.Message{...})

      # Dynamic response based on body
      expect(:send_message, fn body ->
        assert body["text"] =~ "Welcome"
        {:ok, %ExGram.Model.Message{...}}
      end)

      # Dynamic response with count
      expect(:send_message, 2, fn body ->
        {:ok, %ExGram.Model.Message{...}}
      end)

  """
  def expect(action, n \\ 1, response) when is_integer(n) and n > 0 do
    update_owner_metadata(fn meta ->
      expectations =
        Map.update(meta.expectations, action, [{response, n}], fn existing ->
          existing ++ [{response, n}]
        end)

      %{meta | expectations: expectations}
    end)

    :ok
  end

  @doc """
  Get all calls recorded for the current owner.
  """
  def get_calls do
    case fetch_owner_metadata() do
      {:ok, meta} -> meta.calls
      :error -> []
    end
  end

  @doc """
  Verify all expectations were consumed.
  Raises if any expectations remain.
  """
  def verify!(pid \\ self()) do
    case fetch_owner_metadata(pid) do
      {:ok, meta} ->
        errors = []

        # Check for unexpected calls (calls with no stub or expectation)
        errors =
          if meta.unexpected_calls == [] do
            errors
          else
            paths =
              meta.unexpected_calls |> Enum.map(&elem(&1, 0)) |> Enum.reverse() |> Enum.join(", ")

            ["Unexpected API calls with no stub or expectation: #{paths}" | errors]
          end

        # Check for unfulfilled path-specific expectations
        errors =
          if map_size(meta.expectations) > 0 do
            ["Path-specific expectations not fulfilled: #{inspect(meta.expectations)}" | errors]
          else
            errors
          end

        # Check for unfulfilled catch-all expectations
        errors =
          if meta.catch_all_expectations != [] do
            [
              "Catch-all expectations not fulfilled: #{length(meta.catch_all_expectations)} remaining"
              | errors
            ]
          else
            errors
          end

        if errors == [] do
          :ok
        else
          raise Enum.join(errors, "\n")
        end

      :error ->
        # No metadata found - process may have already cleaned up, that's ok
        :ok
    end
  end

  @doc """
  Registers cleanup on test exit that verifies expectations were met.
  Call this in your test's setup block via `setup {ExGram.Test, :verify_on_exit!}`.
  """
  def verify_on_exit!(_context) do
    pid = self()

    # Use manual cleanup to prevent auto-cleanup when test process dies.
    # This ensures ownership persists through the on_exit callback so verify! can check it.
    NimbleOwnership.set_owner_to_manual_cleanup(@ownership_server, pid)

    ExUnit.Callbacks.on_exit({:ex_gram_test, pid}, fn ->
      # Verify expectations and clean up ownership
      verify!(pid)
      NimbleOwnership.cleanup_owner(@ownership_server, pid)
    end)
  end

  @doc """
  Allow another process to use this process's stubs.
  """
  def allow(owner_pid, allowed_pid) do
    NimbleOwnership.allow(@ownership_server, owner_pid, allowed_pid, @ownership_key)
  end

  @doc """
  Switch to global mode (one owner serves all callers).

  ## Examples

      setup {ExGram.Test, :set_global}
  """
  def set_global(context \\ %{})

  def set_global(%{async: true}) do
    raise "ExGram.Test cannot be set to global mode when the ExUnit case is async. " <>
            "If you want to use ExGram.Test in global mode, remove \"async: true\" when using ExUnit.Case"
  end

  def set_global(_) do
    NimbleOwnership.set_mode_to_shared(@ownership_server, self())
  end

  @doc """
  Switch to private mode (per-process isolation).

  ## Examples

      setup {ExGram.Test, :set_private}
  """
  def set_private(_context \\ %{}) do
    NimbleOwnership.set_mode_to_private(@ownership_server)
  end

  @doc """
  Chooses the ExGram.Test mode based on context.

  When `async: true` is used, `set_private/1` is called,
  otherwise `set_global/1` is used.

  ## Examples

      setup {ExGram.Test, :set_from_context}
  """
  @spec set_from_context(term()) :: :ok
  def set_from_context(%{async: true} = _context), do: set_private()
  def set_from_context(_context), do: set_global()

  # ---------------------------------------------------------------------------
  # Backward-compatible wrappers (thin wrappers over new API)
  # ---------------------------------------------------------------------------

  @doc """
  Backward-compatible wrapper. The name parameter is ignored - isolation is now per-process.
  """
  def backdoor_request(path, response, _name \\ nil), do: stub(path, response)

  @doc """
  Backward-compatible wrapper. The name parameter is ignored - isolation is now per-process.
  """
  def backdoor_error(path, error, _name \\ nil), do: stub_error(path, error)

  @doc """
  Backward-compatible wrapper. The name parameter is ignored.
  """
  def get_calls(_name), do: get_calls()

  @doc """
  Backward-compatible wrapper. Cleans the current owner's state.
  """
  def clean(_name \\ nil) do
    update_owner_metadata(fn _meta -> %__MODULE__{} end)
    :ok
  end

  # ---------------------------------------------------------------------------
  # ExGram.Adapter callback
  # ---------------------------------------------------------------------------

  @impl ExGram.Adapter
  def request(verb, path, body, _opts) do
    # Find the owner through the callers chain
    callers = [self() | Process.get(:"$callers", [])]

    case fetch_owner_from_callers(callers) do
      {:ok, owner_pid} ->
        handle_request(owner_pid, verb, path, body)

      :no_expectation ->
        {:error, %ExGram.Error{code: 404, message: "No owner found for adapter test"}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Atomically fetch metadata and record the call to prevent race conditions.
  # If ownership exists but get_and_update fails (race with cleanup_owner),
  # this returns :error and the caller should handle appropriately.
  defp fetch_owner_and_record(owner_pid, call) do
    case get_and_update(owner_pid, fn
           nil ->
             # Ownership exists but metadata is nil - initialize and record
             # This can happen on first call or after a reset
             new_meta = %__MODULE__{calls: [call]}
             {new_meta, new_meta}

           meta ->
             # Ownership and metadata both exist - record the call
             updated_meta = %{meta | calls: meta.calls ++ [call]}
             {meta, updated_meta}
         end) do
      {:ok, meta} ->
        {:ok, meta}

      {:error, %NimbleOwnership.Error{reason: {:not_shared_owner, actual_owner_pid}}} ->
        fetch_owner_and_record(actual_owner_pid, call)

      {:error, %NimbleOwnership.Error{}} ->
        :error
    end
  end

  defp handle_request(owner_pid, verb, path, body) do
    action = path |> clean_path() |> to_action()

    # Atomically fetch metadata and record call to prevent race conditions
    case fetch_owner_and_record(owner_pid, {verb, action, body}) do
      {:ok, meta} ->
        get_response(owner_pid, meta, action, body)

      :error ->
        {:error, %ExGram.Error{code: 404, message: "Owner metadata not found"}}
    end
  end

  defp get_response(owner_pid, meta, action, body) do
    case get_response_from_expect_or_stub(owner_pid, meta, action, body) do
      {:ok, response} ->
        normalize_response(response)

      :not_found ->
        {:error, %ExGram.Error{code: 404, message: "No stub or expectation found for #{action}"}}
    end
  end

  defp get_response_from_expect_or_stub(owner_pid, meta, action, body) do
    # Priority order:
    # 1. Path-specific expectations
    # 2. Catch-all expectations
    # 3. Path-specific stubs/errors
    # 4. Catch-all stub
    case consume_expect_expectation(owner_pid, meta, action, body) do
      {:ok, response} ->
        {:ok, response}

      :not_found ->
        check_stub_expectation(owner_pid, meta, action, body)
    end
  end

  def consume_expect_expectation(owner_pid, meta, action, body) do
    case consume_expectation(owner_pid, meta, action, body) do
      {:ok, response} ->
        {:ok, response}

      :not_found ->
        consume_catch_all_expectation(owner_pid, meta, action, body)
    end
  end

  defp check_stub_expectation(owner_pid, meta, action, body) do
    case check_stubs_and_errors(meta, action, body) do
      :not_found ->
        check_catch_all_stub(owner_pid, meta, action, body)

      response ->
        response
    end
  end

  defp normalize_response({:ok, response}), do: {:ok, response}
  defp normalize_response({:error, response}), do: {:error, response}
  defp normalize_response(response), do: {:ok, response}

  defp consume_expectation(owner_pid, meta, action, body) do
    case Map.get(meta.expectations, action) do
      nil ->
        :not_found

      [] ->
        :not_found

      [{response, 1}] ->
        # Last one - remove the action entirely
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.delete(m.expectations, action)}
        end)

        {:ok, invoke_response(response, action, body)}

      [{response, 1} | rest] ->
        # Last one but more in the list
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.put(m.expectations, action, rest)}
        end)

        {:ok, invoke_response(response, action, body)}

      [{response, n} | rest] when n > 1 ->
        # Decrement count
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.put(m.expectations, action, [{response, n - 1} | rest])}
        end)

        {:ok, invoke_response(response, action, body)}

      [_ | rest] ->
        # Move to next expectation
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.put(m.expectations, action, rest)}
        end)

        consume_expectation(
          owner_pid,
          %{meta | expectations: Map.put(meta.expectations, action, rest)},
          action,
          body
        )
    end
  end

  defp consume_catch_all_expectation(owner_pid, meta, action, body) do
    case meta.catch_all_expectations do
      [] ->
        :not_found

      [{callback, 1}] ->
        # Last one - remove it
        update_owner_metadata(owner_pid, fn m ->
          %{m | catch_all_expectations: []}
        end)

        {:ok, invoke_response(callback, action, body)}

      [{callback, n} | rest] when n > 1 ->
        # Decrement count
        update_owner_metadata(owner_pid, fn m ->
          %{m | catch_all_expectations: [{callback, n - 1} | rest]}
        end)

        {:ok, invoke_response(callback, action, body)}

      [_head | rest] ->
        # Move to next expectation
        update_owner_metadata(owner_pid, fn m ->
          %{m | catch_all_expectations: rest}
        end)

        consume_catch_all_expectation(
          owner_pid,
          %{meta | catch_all_expectations: rest},
          action,
          body
        )
    end
  end

  defp check_stubs_and_errors(meta, action, body) do
    # Check errors first, then stubs
    cond do
      Map.has_key?(meta.errors, action) ->
        {:ok, {:error, Map.get(meta.errors, action)}}

      Map.has_key?(meta.responses, action) ->
        {:ok, invoke_response(Map.get(meta.responses, action), action, body)}

      true ->
        :not_found
    end
  end

  defp check_catch_all_stub(owner_pid, meta, action, body) do
    case meta.catch_all_stub do
      nil ->
        # Record as unexpected call
        update_owner_metadata(owner_pid, fn m ->
          %{m | unexpected_calls: [{action, body} | m.unexpected_calls]}
        end)

        :not_found

      callback ->
        {:ok, invoke_response(callback, action, body)}
    end
  end

  defp wrap_response({:ok, response}), do: {:ok, response}
  defp wrap_response({:error, error}), do: {:error, error}
  defp wrap_response(response), do: {:ok, response}

  # Invoke a response - handles both static values and callbacks
  # For callbacks: action parameter is an atom like :send_message
  defp invoke_response(response, _action, body) when is_function(response, 1) do
    response.(body)
  end

  defp invoke_response(response, action, body) when is_function(response, 2) do
    response.(action, body)
  end

  defp invoke_response(response, _action, _body) do
    wrap_response(response)
  end

  defp fetch_owner_metadata do
    fetch_owner_metadata(self())
  end

  defp fetch_owner_metadata(owner_pid) do
    case get_and_update(owner_pid, fn
           nil -> {nil, %__MODULE__{}}
           meta -> {meta, meta}
         end) do
      {:ok, nil} -> :error
      {:ok, meta} -> {:ok, meta}
      {:error, _} -> :error
    end
  end

  defp update_owner_metadata(fun) do
    update_owner_metadata(self(), fun)
  end

  defp update_owner_metadata(owner_pid, fun) do
    get_and_update!(owner_pid, fn
      nil ->
        new_meta = fun.(%__MODULE__{})
        {new_meta, new_meta}

      meta ->
        new_meta = fun.(meta)
        {new_meta, new_meta}
    end)
  end

  defp get_and_update(owner_pid, update_fun) do
    NimbleOwnership.get_and_update(@ownership_server, owner_pid, @ownership_key, update_fun, @timeout)
  end

  defp get_and_update!(owner_pid, update_fun) do
    case get_and_update(owner_pid, update_fun) do
      {:ok, return} -> return
      {:error, %NimbleOwnership.Error{} = error} -> raise error
    end
  end

  defp fetch_owner_from_callers(caller_pids) do
    # If the mock doesn't have an owner, it can't have expectations so we return :no_expectation.
    case NimbleOwnership.fetch_owner(@ownership_server, caller_pids, @ownership_key, @timeout) do
      {tag, owner_pid} when tag in [:shared_owner, :ok] -> {:ok, owner_pid}
      :error -> :no_expectation
    end
  end

  # ---------------------------------------------------------------------------
  # Conversion helpers
  # ---------------------------------------------------------------------------

  defp to_action(path) when is_binary(path) do
    path
    |> String.trim_leading("/")
    |> Macro.underscore()
    |> String.to_atom()
  end

  defp to_action(action) when is_atom(action), do: action

  defp clean_path("/bot" <> _ = path) do
    "/" <> (path |> String.split("/") |> Enum.drop(2) |> Enum.join("/"))
  end

  defp clean_path(path), do: path
end
