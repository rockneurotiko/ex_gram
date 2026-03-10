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

  You can learn more in the [testing guide](https://hexdocs.pm/ex_gram/testing.html)

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
  # Exceptions
  # ---------------------------------------------------------------------------

  defmodule UnexpectedCallError do
    @moduledoc false
    defexception [:message]
  end

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Starts the NimbleOwnership server used to track per-test ownership for ExGram.Adapter.Test.
  
  Accepts the same options as NimbleOwnership.start_link/1. By default sets the `:name` option to the module's ownership server name so the server can be referenced globally; call this once (for example from test_helper.exs or your application supervision tree).
  """
  @spec start_link(Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @ownership_server)
    NimbleOwnership.start_link(opts)
  end

  @doc """
  Provide a child specification for supervising the test ownership server.
  
  Parameters
  
    - opts: Keyword list of options forwarded to start_link/1.
  
  The returned map is a child specification suitable for use in a supervision tree.
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
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
  Register a catch-all stub callback for the current owner to handle requests that have no path-specific stub.
  
  The provided `callback` will be invoked with the action (an atom) and the request body when no action-specific stub or expectation matches; its return value is used as the response (for example `{:ok, value}` or `{:error, reason}`).
  
  ## Parameters
  
    - callback: a function of arity 2 receiving `(action :: atom(), body :: any())`.
  
  ## Example
  
      stub(fn action, body ->
        case action do
          :send_message -> {:ok, %ExGram.Model.Message{...}}
          :send_chat_action -> {:ok, true}
        end
      end)
  
  """
  @spec stub((atom(), any() -> any())) :: :ok
  def stub(callback) when is_function(callback, 2) do
    update_owner_metadata(fn meta ->
      %{meta | catch_all_stub: callback}
    end)

    :ok
  end

  @doc """
  Register a path- or action-specific stub response for the current owner.
  
  The provided response will be used whenever a request matches the given action and is stored in the calling process's metadata.
  
  Accepted response forms:
  - a static value (non-tuple values are wrapped as `{:ok, value}`)
  - a function of arity 1 receiving the request body
  - a function of arity 2 receiving the action and the request body
  
  ## Parameters
  
    - action: an action atom or API path string to match incoming requests.
    - response: a static response or responder function as described above.
  
  ## Examples
  
      # Static response with atom
      stub(:send_message, %ExGram.Model.Message{...})
  
      # Dynamic response based on body
      stub(:send_message, fn body ->
        assert body["text"] =~ "Hello"
        {:ok, %ExGram.Model.Message{...}}
      end)
  
  """
  @spec stub(term(), term()) :: :ok
  def stub(action, response) do
    update_owner_metadata(fn meta ->
      %{meta | responses: Map.put(meta.responses, action, response)}
    end)

    :ok
  end

  @doc """
  Configure a persistent error response for a Telegram API path or action for the current owner.
  
  This records an error that will be returned whenever a request matches the given `action`. The configuration is stored for the calling process (owner) and persists until cleared or the owner is reset.
  
  ## Parameters
  
    - action: a binary path (e.g., "/sendMessage") or an action atom used to match requests.
    - error: the error value to return when the action is invoked.
  
  """
  @spec stub_error(binary() | atom(), any()) :: :ok
  def stub_error(action, error) do
    update_owner_metadata(fn meta ->
      %{meta | errors: Map.put(meta.errors, action, error)}
    end)

    :ok
  end

  @doc """
  Register a catch-all expectation callback that will be consumed once.
  
  The callback is invoked for any action and receives the action atom and the request body; it should return a response in the same shapes accepted by the adapter (e.g., `{:ok, response}` or `{:error, reason}`).
  
  ## Parameters
  
    - callback: a function of arity 2 that accepts `(action :: atom, body :: any)` and returns a response.
  
  ## Example
  
      expect(fn action, body ->
        assert action == :send_message
        {:ok, %ExGram.Model.Message{...}}
      end)
  
  """
  @spec expect((any, any -> any)) :: :ok
  def expect(callback) when is_function(callback, 2) do
    expect(1, callback)
  end

  @doc """
  Registers a catch-all expectation that will be consumed after `n` matching requests.
  
  The provided `callback` is invoked with the action (`atom`) and the request body when a request does not match a path-specific expectation or stub. The expectation is removed after it has been used `n` times.
  
  ## Parameters
  
    - `n`: positive integer number of times the expectation should be consumed.
    - `callback`: a function of arity 2 called as `callback.(action, body)` where `action` is an atom and `body` is the request payload.
  
  """
  @spec expect(pos_integer(), (atom(), any() -> any())) :: :ok
  def expect(n, callback) when is_integer(n) and n > 0 and is_function(callback, 2) do
    update_owner_metadata(fn meta ->
      %{meta | catch_all_expectations: meta.catch_all_expectations ++ [{callback, n}]}
    end)

    :ok
  end

  @doc """
  Register an expectation for the given action that will be consumed after n calls.
  
  Expectations are checked before stubs. The provided response will be returned when the action is requested and the expectation is matched; each registration is consumed after its remaining count reaches zero and then removed.
  
  Response forms:
    - A static value (will be normalized to `{:ok, value}`).
    - A function of arity 1 that receives the request body.
    - A function of arity 2 that receives the action and the request body.
  
  ## Parameters
  
    - action: An action atom (the path/action to expect).
    - n: Positive integer for how many times the expectation should be consumed (default: 1).
    - response: The response value or callback invoked when the expectation matches.
  
  ## Examples
  
      expect(:send_message, %ExGram.Model.Message{...})
      expect(:send_message, 2, %ExGram.Model.Message{...})
      expect(:send_message, fn body -> {:ok, %ExGram.Model.Message{...}} end)
      expect(:send_message, 2, fn _action, body -> {:ok, %ExGram.Model.Message{...}} end)
  
  """
  @spec expect(atom(), pos_integer(), any()) :: :ok
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
  Retrieve the list of calls recorded for the current owner.
  
  Returns a list of recorded calls for the current owner; returns an empty list if no owner metadata is present.
  """
  @spec get_calls() :: list()
  def get_calls do
    case fetch_owner_metadata() do
      {:ok, meta} -> meta.calls
      :error -> []
    end
  end

  @doc """
  Verify that all registered expectations were consumed for the given owner process.
  
  Checks for unexpected calls, unfulfilled path-specific expectations, and unfulfilled catch-all expectations; raises an error with details if any remain.
  
  ## Parameters
  
    - pid: PID of the owner process to verify (defaults to the current process).
  
  """
  @spec verify!(pid()) :: :ok
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
          if meta.catch_all_expectations == [] do
            errors
          else
            [
              "Catch-all expectations not fulfilled: #{length(meta.catch_all_expectations)} remaining"
              | errors
            ]
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

  # We need to ignore warnings because ExUnit is not loaded
  @dialyzer {:nowarn_function, verify_on_exit!: 1}
  @doc """
  Registers an on-exit hook that verifies expectations and cleans up adapter ownership for the current test process.
  
  Sets the test process to manual cleanup so ownership remains available inside the on-exit callback, then registers an exit callback that calls `verify!/1` for the process and removes its ownership. Call from a test setup block as `setup {ExGram.Test, :verify_on_exit!}`.
  """
  @spec verify_on_exit!(term()) :: :ok
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
  Allows another process to use the stubs and expectations owned by `owner_pid`.
  
  ## Parameters
  
    - owner_pid: PID of the owner process whose stubs and expectations will be shared.
    - allowed_pid: PID of the process being granted access.
  """
  @spec allow(pid(), pid()) :: :ok | {:error, term()}
  def allow(owner_pid, allowed_pid) do
    NimbleOwnership.allow(@ownership_server, owner_pid, allowed_pid, @ownership_key)
  end

  @doc """
Set the adapter to global mode so a single owner serves all callers.

When invoked with a test context that has `:async` set to `true`, this call will fail (global mode is not allowed in async tests).

## Parameters

  - context: Test context map used to detect async tests (defaults to `%{}`).

## Examples

    setup {ExGram.Test, :set_global}

"""
@spec set_global(map()) :: :ok
  def set_global(context \\ %{})

  @doc """
  Prevent switching ExGram.Test to global mode in async test contexts.
  
  Raises a `RuntimeError` when the provided `context` has `:async` set to `true`,
  with instructions to remove `async: true` from the ExUnit case in order to use global mode.
  """
  @spec set_global(map()) :: :ok
  def set_global(%{async: true}) do
    raise "ExGram.Test cannot be set to global mode when the ExUnit case is async. " <>
            "If you want to use ExGram.Test in global mode, remove \"async: true\" when using ExUnit.Case"
  end

  @doc """
  Switches the test ownership server to shared (global) mode for the current process.
  
  This makes the current process's stubs, expectations, and recorded calls accessible to other processes via the ownership server.
  """
  @spec set_global(term()) :: :ok
  def set_global(_) do
    NimbleOwnership.set_mode_to_shared(@ownership_server, self())
  end

  @doc """
  Switches the ownership server to private mode, enabling per-process isolation.
  
  ## Examples
  
      setup {ExGram.Test, :set_private}
  """
  @spec set_private(term()) :: :ok
  def set_private(_context \\ %{}) do
    NimbleOwnership.set_mode_to_private(@ownership_server)
  end

  
  
  @doc """
Selects private or global test mode based on the context's :async flag.

If `context` is a map containing `:async` set to `true`, the function enables private per-process mode; otherwise it enables global/shared mode.

## Parameters

  - context: a map (typically the test context) where the `:async` boolean controls mode selection.

@returns

  - `:ok`
"""
@spec set_from_context(term()) :: :ok
def set_from_context(%{async: true} = _context), do: set_private()
  @doc """
Switches the adapter to global (shared) mode when the provided test context does not require private mode.

If the context indicates an async test (`%{async: true}`), other clauses handle selecting private mode; this clause falls back to enabling global mode.

## Parameters

  - context: Test context map or term used to decide global vs private mode (commonly includes `:async`).

@spec set_from_context(term()) :: :ok
"""
def set_from_context(_context), do: set_global()

  # ---------------------------------------------------------------------------
  # Backward-compatible wrappers (thin wrappers over new API)
  # ---------------------------------------------------------------------------

  @doc """
Registers a stubbed response for the given API path using the legacy backdoor API.

The third `name` argument is ignored (isolation is per-process); use `path` and `response` to configure the stub.
"""
@spec backdoor_request(binary() | atom(), term(), term()) :: term()
  def backdoor_request(path, response, _name \\ nil), do: stub(path, response)

  @doc """
Backward-compatible alias for stubbing an error for a given API path; the `name` argument is ignored.

Delegates to `stub_error/2`. Provided for compatibility with older test code that passed a `name` argument; isolation is managed per-process and the third argument has no effect.

## Parameters

  - path: API path (string) or action atom to stub.
  - error: value or structure that should be returned as an error for the given path.
  - _name: ignored (kept for backward compatibility).

"""
@spec backdoor_error(binary() | atom(), any(), any()) :: :ok
  def backdoor_error(path, error, _name \\ nil), do: stub_error(path, error)

  @doc """
Compatibility wrapper that retrieves recorded calls for the current owner. The `name` argument is ignored.

## Parameters

  - name: Ignored; present for backward compatibility.

## Returns

  - A list of recorded calls.
"""
@spec get_calls(term()) :: list()
  def get_calls(_name), do: get_calls()

  @doc """
  Resets the current owner's test adapter state to a fresh, empty state.
  
  Replaces any recorded responses, errors, expectations, calls, and catch-all stubs/expectations for the current owner.
  
  """
  @spec clean(term()) :: :ok
  def clean(_name \\ nil) do
    update_owner_metadata(fn _meta -> %__MODULE__{} end)
    :ok
  end

  # ---------------------------------------------------------------------------
  # ExGram.Adapter callback
  # ---------------------------------------------------------------------------

  @impl ExGram.Adapter
  @doc """
  Dispatches a request to the test owner that owns the current caller chain and returns the owner's configured response.
  
  Resolves the owning process for the current caller chain, converts the request path into an action, and delegates handling to that owner. Raises UnexpectedCallError if no owner has an expectation or stub for the action.
  """
  @spec request(term(), String.t(), term(), term()) :: {:ok, term()} | {:error, term()}
  def request(verb, path, body, _opts) do
    # Find the owner through the callers chain
    callers = [self() | caller_pids()]
    action = path |> clean_path() |> to_action()

    case fetch_owner_from_callers(callers) do
      {:ok, owner_pid} ->
        handle_request(owner_pid, verb, action, body)

      :no_expectation ->
        raise UnexpectedCallError,
              "no expectation defined for action #{action} in #{format_process()} with body #{inspect(body)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp format_process do
    callers = caller_pids()

    "process #{inspect(self())}" <>
      if Enum.empty?(callers) do
        ""
      else
        " (or in its callers #{inspect(callers)})"
      end
  end

  # Find the pid of the actual caller
  defp caller_pids do
    case Process.get(:"$callers") do
      nil -> []
      pids when is_list(pids) -> pids
    end
  end

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

  defp handle_request(owner_pid, verb, action, body) do
    # Atomically fetch metadata and record call to prevent race conditions
    case fetch_owner_and_record(owner_pid, {verb, action, body}) do
      {:ok, meta} ->
        get_response(owner_pid, meta, action, body)

      :error ->
        # Record as unexpected call
        update_owner_metadata(owner_pid, fn m ->
          %{m | unexpected_calls: [{action, body} | m.unexpected_calls]}
        end)

        {:error, %ExGram.Error{code: 404, message: "Owner metadata not found"}}
    end
  end

  defp get_response(owner_pid, meta, action, body) do
    case get_response_from_expect_or_stub(owner_pid, meta, action, body) do
      {:ok, response} ->
        normalize_response(response)

      :not_found ->
        # Record as unexpected call
        update_owner_metadata(owner_pid, fn m ->
          %{m | unexpected_calls: [{action, body} | m.unexpected_calls]}
        end)

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
        check_stub_expectation(meta, action, body)
    end
  end

  @doc """
  Attempt to consume a path-specific expectation for the given action; if none is available, try to consume a catch-all expectation.
  """
  @spec consume_expect_expectation(pid(), map(), atom(), any()) :: {:ok, any()} | :not_found
  def consume_expect_expectation(owner_pid, meta, action, body) do
    case consume_expectation(owner_pid, meta, action, body) do
      {:ok, response} ->
        {:ok, response}

      :not_found ->
        consume_catch_all_expectation(owner_pid, meta, action, body)
    end
  end

  defp check_stub_expectation(meta, action, body) do
    case check_stubs_and_errors(meta, action, body) do
      :not_found ->
        check_catch_all_stub(meta, action, body)

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

      [{callback, 1} | rest] ->
        # Last one - remove it
        update_owner_metadata(owner_pid, fn m ->
          %{m | catch_all_expectations: rest}
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

  defp check_catch_all_stub(meta, action, body) do
    case meta.catch_all_stub do
      nil ->
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
