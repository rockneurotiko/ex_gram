defmodule ExGram.Updates.Polling do
  @moduledoc """
  Updates implementation using the polling method.

  This GenServer continuously polls the Telegram Bot API for new updates using
  `ExGram.get_updates!/1` with long polling (50 second timeout by default).

  Automatically deletes any existing webhook on startup (configurable with
  `:delete_webhook` option).

  Configured with `config :ex_gram, updates: ExGram.Updates.Polling, polling: [...]`.

  See the [Polling and Webhooks guide](polling-and-webhooks.md) for more details.
  """

  use GenServer

  require Logger

  @polling_timeout 100

  def start_link(%{bot: pid, token: token} = opts) do
    opts = Map.drop(opts, [:bot, :token])
    GenServer.start_link(__MODULE__, {:ok, pid, token, opts})
  end

  def init({:ok, pid, token, opts}) do
    opts = :ex_gram |> ExGram.Config.get(:polling, []) |> Keyword.merge(Keyword.new(opts))

    if Keyword.get(opts, :delete_webhook, true) do
      # Clean webhook
      ExGram.delete_webhook(token: token)
    end

    Process.send_after(self(), {:fetch, :update_id}, @polling_timeout)
    {:ok, {pid, token, -1, opts}}
  end

  def handle_cast({:fetch, :update_id} = m, state), do: handle_info(m, state)

  def handle_info(:timeout, state), do: handle_info({:fetch, :update_id}, state)

  def handle_info({:fetch, :update_id}, {pid, token, uid, opts}) do
    updates = get_updates(token, uid, opts)
    send_updates(updates, pid)

    nid = next_pid(uid, updates)

    {:noreply, {pid, token, nid, opts}, @polling_timeout}
  end

  def handle_info(unknown_message, state) do
    Logger.debug("Polling updates received an unknown message #{inspect(unknown_message)}")

    {:noreply, state, @polling_timeout}
  end

  @default_opts [limit: 100, timeout: 50]
  defp get_updates(token, uid, opts) do
    opts = Keyword.take(opts, [:allowed_updates])

    opts =
      @default_opts
      |> Keyword.merge(opts)
      |> Keyword.put(:offset, uid)
      |> Keyword.put(:token, token)

    try do
      ExGram.get_updates!(opts)
    rescue
      e in ExGram.Error ->
        formatted_error = Exception.format(:error, e, __STACKTRACE__)
        Logger.error("[ExGram] Error fetching updates: #{formatted_error}")
        []
    end
  end

  defp send_updates(updates, pid) do
    Enum.map(updates, &GenServer.call(pid, {:update, &1}))
  end

  defp next_pid(actual, []), do: actual

  defp next_pid(actual, updates) do
    updates
    |> Stream.map(&(&1.update_id + 1))
    |> Enum.reduce(actual, &max(&1, &2))
  end
end
