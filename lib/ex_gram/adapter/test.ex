defmodule ExGram.Adapter.Test do
  @moduledoc """
  HTTP Adapter for testing, it allows you to setup request responses and errors
  """

  @behaviour ExGram.Adapter

  @name __MODULE__

  defstruct calls: [], responses: %{}, errors: %{}

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, @name)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl ExGram.Adapter
  def request(verb, path, body, name \\ @name) do
    GenServer.call(name, {:request, verb, path, body})
  end

  def backdoor_request(path, response, name \\ @name) do
    GenServer.call(name, {:backdoor, path, response})
  end

  def backdoor_error(path, error, name \\ @name) do
    GenServer.call(name, {:backdoor_error, path, error})
  end

  def clean(name \\ @name) do
    GenServer.call(name, {:clean})
  end

  def handle_call({:request, verb, path, body}, _, state) do
    state = add_call(state, {verb, path, body})

    reply = get_response(state, path)

    {:reply, reply, state}
  end

  def handle_call({:backdoor, path, response}, _, %{responses: responses} = state) do
    path = clean_path(path)
    responses = Map.put(responses, path, response)
    {:reply, :ok, %{state | responses: responses}}
  end

  def handle_call({:backdoor_error, path, error}, _, %{errors: errors} = state) do
    path = clean_path(path)
    errors = Map.put(errors, path, error)
    {:reply, :ok, %{state | errors: errors}}
  end

  def handle_call({:clean}, _, _) do
    {:reply, :ok, %__MODULE__{}}
  end

  defp add_call(%{calls: calls} = state, data), do: %{state | calls: calls ++ [data]}

  defp get_response(%{responses: responses, errors: errors}, path) do
    path = clean_path(path)

    with {:error, :error} <- {:error, Map.fetch(errors, path)},
         {:ok, value} <- Map.fetch(responses, path) do
      {:ok, value}
    else
      {:error, {:ok, value}} -> {:error, value}
      _ -> {:error, %ExGram.Error{code: 404}}
    end
  end

  defp clean_path("/bot" <> _ = path),
    do: "/" <> (path |> String.split("/") |> Enum.drop(2) |> Enum.join("/"))

  defp clean_path(path), do: path
end
