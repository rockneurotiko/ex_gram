defmodule ExGram.Updates.Polling do
  use GenServer
  require Logger

  @polling_timeout 100

  def start_link({:bot, pid, :token, token}) do
    # Logger.debug "START WORKER"
    # TODO: Use name
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    # Clean webhook
    ExGram.delete_webhook(token: token)

    Process.send_after(self(), {:fetch, :update_id}, @polling_timeout)
    {:ok, {pid, token, -1}}
  end

  def handle_cast({:fetch, :update_id} = m, state), do: handle_info(m, state)

  def handle_info(:timeout, state), do: handle_info({:fetch, :update_id}, state)

  def handle_info({:fetch, :update_id}, {pid, token, uid}) do
    updates = get_updates(token, uid)
    send_updates(updates, pid)

    nid = extract_last_pid(uid, updates)

    {:noreply, {pid, token, nid + 1}, @polling_timeout}
  end

  def handle_info(unknonwn_message, state) do
    Logger.debug("Polling updates received an unknown message #{inspect(unknonwn_message)}")

    {:noreply, state, @polling_timeout}
  end

  @default_opts [limit: 100, timeout: 30000]
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
    Enum.map(updates, &GenServer.call(pid, {:update, &1}))
  end

  defp extract_last_pid(actual, []), do: actual

  defp extract_last_pid(actual, [u | us]) do
    au = u.update_id

    extract_last_pid(max(au, actual), us)
  end
end
