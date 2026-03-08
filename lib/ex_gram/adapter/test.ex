defmodule ExGram.Adapter.Test do
  @moduledoc """
  HTTP Adapter for testing with per-process isolation using NimbleOwnership.

  Supports both private mode (per-process stubs for async tests) and global mode
  (shared stubs for synchronous tests).

  ## Usage

      # In test_helper.exs or application
      ExGram.Adapter.Test.start_link()

      # In your test
      test "my test" do
        ExGram.Adapter.Test.stub(:send_message, %{"ok" => true})
        ExGram.Adapter.Test.expect(:get_me, %{"id" => 1})

        # Make API calls
        ExGram.send_message(123, "Hello")

        # Verify expectations and get calls (calls are recorded as atoms)
        calls = ExGram.Adapter.Test.get_calls()
        # calls = [{:post, :send_message, %{"chat_id" => 123, ...}}]

        ExGram.Adapter.Test.verify!()
      end

  ## API Methods

  All stub and expect functions accept either action atoms (`:send_message`) or
  path strings (`"/sendMessage"`). Internally, paths are converted to atoms for
  consistency. Callbacks receive action atoms.
  """

  @behaviour ExGram.Adapter

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
  # Conversion helpers
  # ---------------------------------------------------------------------------

  @doc """
  Convert an atom action name to a Telegram API path string.

  Examples:
      iex> to_path(:send_message)
      "/sendMessage"

      iex> to_path(:get_me)
      "/getMe"

      iex> to_path("/sendMessage")
      "/sendMessage"
  """
  def to_path(action) when is_atom(action) do
    action
    |> Atom.to_string()
    |> camelize_first_lower()
    |> then(&"/#{&1}")
  end

  def to_path(path) when is_binary(path), do: path

  @doc """
  Convert a Telegram API path string to an atom action name.

  Examples:
      iex> to_action("/sendMessage")
      :send_message

      iex> to_action(:send_message)
      :send_message
  """
  def to_action(path) when is_binary(path) do
    path
    |> String.trim_leading("/")
    |> Macro.underscore()
    |> String.to_atom()
  end

  def to_action(action) when is_atom(action), do: action

  # Convert snake_case string to lowerCamelCase
  defp camelize_first_lower(string) do
    string
    |> Macro.camelize()
    |> then(fn <<first::utf8, rest::binary>> -> String.downcase(<<first::utf8>>) <> rest end)
  end

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

      # Static response with path string
      stub("/sendMessage", %ExGram.Model.Message{...})

      # Dynamic response based on body
      stub(:send_message, fn body ->
        assert body["text"] =~ "Hello"
        {:ok, %ExGram.Model.Message{...}}
      end)

  """
  def stub(path_or_action, response) do
    path = path_or_action |> to_path() |> clean_path()

    update_owner_metadata(fn meta ->
      %{meta | responses: Map.put(meta.responses, path, response)}
    end)

    :ok
  end

  @doc """
  Stub an error for a Telegram API path or action atom. Always returns this error.
  Owned by the calling process.
  """
  def stub_error(path_or_action, error) do
    path = path_or_action |> to_path() |> clean_path()

    update_owner_metadata(fn meta ->
      %{meta | errors: Map.put(meta.errors, path, error)}
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
  def expect(path_or_action, n \\ 1, response) when is_integer(n) and n > 0 do
    path = path_or_action |> to_path() |> clean_path()

    update_owner_metadata(fn meta ->
      expectations =
        Map.update(meta.expectations, path, [{response, n}], fn existing ->
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
          if length(meta.catch_all_expectations) > 0 do
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

      _ ->
        :ok
    end
  end

  def verify_on_exit!(_context) do
    pid = self()
    NimbleOwnership.set_owner_to_manual_cleanup(@ownership_server, pid)

    ExUnit.Callbacks.on_exit(Mox, fn ->
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
  """
  def set_global do
    NimbleOwnership.set_mode_to_shared(@ownership_server, self())
  end

  @doc """
  Switch to private mode (per-process isolation).
  """
  def set_private do
    NimbleOwnership.set_mode_to_private(@ownership_server)
  end

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

    case NimbleOwnership.fetch_owner(@ownership_server, callers, @ownership_key) do
      {:ok, owner_pid} ->
        handle_request(owner_pid, verb, path, body)

      {:shared_owner, owner_pid} ->
        handle_request(owner_pid, verb, path, body)

      :error ->
        {:error, %ExGram.Error{code: 404, message: "No owner found for adapter test"}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp handle_request(owner_pid, verb, path, body) do
    path = clean_path(path)
    action = to_action(path)

    # Record the call with action atom
    record_call(owner_pid, {verb, action, body})

    # Look up response (still uses path string for internal storage)
    case fetch_owner_metadata(owner_pid) do
      {:ok, meta} ->
        get_response(owner_pid, meta, path, action, body)

      :error ->
        {:error, %ExGram.Error{code: 404, message: "Owner metadata not found"}}
    end
  end

  defp record_call(owner_pid, call) do
    update_owner_metadata(owner_pid, fn meta ->
      %{meta | calls: meta.calls ++ [call]}
    end)
  end

  defp get_response(owner_pid, meta, path, action, body) do
    # Priority order:
    # 1. Path-specific expectations
    # 2. Catch-all expectations
    # 3. Path-specific stubs/errors
    # 4. Catch-all stub
    case consume_expectation(owner_pid, meta, path, action, body) do
      {:ok, response} ->
        response

      :not_found ->
        case consume_catch_all_expectation(owner_pid, meta, action, body) do
          {:ok, response} ->
            response

          :not_found ->
            case check_stubs_and_errors(meta, path, action, body) do
              :not_found ->
                check_catch_all_stub(owner_pid, meta, path, action, body)

              response ->
                response
            end
        end
    end
  end

  defp consume_expectation(owner_pid, meta, path, action, body) do
    case Map.get(meta.expectations, path) do
      nil ->
        :not_found

      [] ->
        :not_found

      [{response, 1}] ->
        # Last one - remove the path entirely
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.delete(m.expectations, path)}
        end)

        {:ok, invoke_response(response, action, body)}

      [{response, n} | rest] when n > 1 ->
        # Decrement count
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.put(m.expectations, path, [{response, n - 1} | rest])}
        end)

        {:ok, invoke_response(response, action, body)}

      [_ | rest] ->
        # Move to next expectation
        update_owner_metadata(owner_pid, fn m ->
          %{m | expectations: Map.put(m.expectations, path, rest)}
        end)

        consume_expectation(
          owner_pid,
          %{meta | expectations: Map.put(meta.expectations, path, rest)},
          path,
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

  defp check_stubs_and_errors(meta, path, action, body) do
    # Check errors first, then stubs
    cond do
      Map.has_key?(meta.errors, path) ->
        {:error, Map.get(meta.errors, path)}

      Map.has_key?(meta.responses, path) ->
        invoke_response(Map.get(meta.responses, path), action, body)

      true ->
        :not_found
    end
  end

  defp check_catch_all_stub(owner_pid, meta, path, action, body) do
    case meta.catch_all_stub do
      nil ->
        # Record as unexpected call
        update_owner_metadata(owner_pid, fn m ->
          %{m | unexpected_calls: [{action, body} | m.unexpected_calls]}
        end)

        {:error, %ExGram.Error{code: 404, message: "No stub or expectation for #{path}"}}

      callback ->
        invoke_response(callback, action, body)
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
    case NimbleOwnership.get_and_update(@ownership_server, owner_pid, @ownership_key, fn
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
    case NimbleOwnership.get_and_update(@ownership_server, owner_pid, @ownership_key, fn
           nil ->
             new_meta = fun.(%__MODULE__{})
             {new_meta, new_meta}

           meta ->
             new_meta = fun.(meta)
             {new_meta, new_meta}
         end) do
      {:ok, meta} -> meta
      {:error, _} -> %__MODULE__{}
    end
  end

  defp clean_path("/bot" <> _ = path) do
    "/" <> (path |> String.split("/") |> Enum.drop(2) |> Enum.join("/"))
  end

  defp clean_path(path), do: path
end
