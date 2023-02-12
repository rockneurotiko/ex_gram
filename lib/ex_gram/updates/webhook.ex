defmodule ExGram.Updates.Webhook do
  @moduledoc """
  Updates implementation that uses polling method
  """

  use GenServer
  require Logger

  def update(update) do
    update |> IO.inspect(label: "webhook genserver")
    GenServer.cast(__MODULE__, {:update, update})
  end

  # @polling_timeout 100

  def handle_cast({:update, update}, {pid, token, uid}) do
    IO.inspect(pid)
    IO.inspect(token)
    IO.inspect(uid)
    update |> IO.inspect(label: "webhook genserver handle_cast")
    send_updates([update], pid)

    {:noreply, {pid, token, -1}}
  end

  def start_link({:bot, pid, :token, token}) do
    # Logger.debug "START WORKER"
    GenServer.start_link(__MODULE__, {:ok, pid, token}, name: __MODULE__)
  end

  def init({:ok, pid, token}) do
    # Clean webhook
    # ExGram.delete_webhook(token: token)

    # Process.send_after(self(), {:fetch, :update_id}, @polling_timeout)
    {:ok, {pid, token, -1}}
  end

  def handle_cast({:fetch, :update_id} = m, state), do: handle_info(m, state)

  def handle_info(:timeout, state), do: handle_info({:fetch, :update_id}, state)

  def handle_info({:fetch, :update_id}, {pid, token, uid}) do
    updates = get_updates(token, uid)
    send_updates(updates, pid)

    nid = next_pid(uid, updates)

    {:noreply, {pid, token, nid}}
  end

  def handle_info(unknown_message, state) do
    Logger.debug("Polling updates received an unknown message #{inspect(unknown_message)}")

    {:noreply, state}
  end

  @default_opts [limit: 100, timeout: 50]
  defp get_updates(token, uid, opts \\ []) do
    opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Keyword.put(:offset, uid)
      |> Keyword.put(:token, token)

    try do
      ExGram.get_updates!(opts)
    rescue
      ExGram.Error -> []
    end
  end

  defp send_updates(updates, pid) do
    IO.inspect(updates, label: "send_updates genserver")
    Enum.map(updates, &GenServer.call(pid, {:update, &1}))
  end

  defp next_pid(actual, []), do: actual

  defp next_pid(actual, updates) do
    updates
    |> Stream.map(&(&1.update_id + 1))
    |> Enum.reduce(actual, &max(&1, &2))
  end
end
