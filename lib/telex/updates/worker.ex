defmodule Telex.Updates.Worker do
  use GenServer
  require Logger

  def start_link({:bot, pid}) do
    Logger.debug "START WORKER"
    GenServer.start_link(__MODULE__, {:ok, pid})
  end

  def init({:ok, pid}) do
    Process.send_after(self(), {:fetch, :update_id, -1}, 1000)
    {:ok, pid}
  end

  def handle_cast({:fetch, :update_id, _} = m, state), do: handle_info(m, state)

  def handle_info({:fetch, :update_id, uid}, pid) do
    Logger.debug "GetUpdates!"
    # If timeout, keep going!
    updates = Telex.get_updates! offset: uid, timeout: 30000

    Enum.map(updates, &(GenServer.call(pid, {:update, &1})))

    nid = extract_last_pid(uid, updates)

    GenServer.cast(self(), {:fetch, :update_id, nid + 1})

    {:noreply, pid}
  end

  defp extract_last_pid(actual, []), do: actual

  defp extract_last_pid(actual, [u|us]) do
    au = u.update_id

    extract_last_pid(max(au, actual), us)
  end
end
