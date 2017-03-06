defmodule Telex.Updates.Worker do
  use GenServer
  require Logger

  def start_link({:bot, pid, :token, token}) do
    Logger.debug "START WORKER"
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    Telex.delete_webhook token: token # Clean webhook

    Process.send_after(self(), {:fetch, :update_id, -1}, 1000)
    {:ok, {pid, token}}
  end

  def handle_cast({:fetch, :update_id, _} = m, state), do: handle_info(m, state)

  def handle_info({:fetch, :update_id, uid}, {pid, token} = state) do
    Logger.debug "GetUpdates!"
    # TODO: If timeout, keep going!
    try do
      updates = Telex.get_updates!(limit: 100, offset: uid, timeout: 30000, token: token)
      Enum.map(updates, &(GenServer.call(pid, {:update, &1})))

      nid = extract_last_pid(uid, updates)

      GenServer.cast(self(), {:fetch, :update_id, nid + 1})

    rescue
      Maxwell.Error ->
        Process.send_after(self(), {:fetch, :update_id, uid}, 1)
    end

    {:noreply, state}
  end

  defp extract_last_pid(actual, []), do: actual

  defp extract_last_pid(actual, [u|us]) do
    au = u.update_id

    extract_last_pid(max(au, actual), us)
  end
end
