defmodule ExGram.Updates.Webhook do
  @moduledoc """
  Updates implementation that uses webhook method
  """

  use GenServer
  require Logger

  def update(update) do
    GenServer.cast(__MODULE__, {:update, update})
  end

  def start_link({:bot, pid, :token, token}) do
    GenServer.start_link(__MODULE__, {:ok, pid, token}, name: __MODULE__)
  end

  def init({:ok, pid, token}) do
    # Clean webhook
    # ExGram.delete_webhook(token: token)

    {:ok, {pid, token, -1}}
  end

  def handle_cast({:update, update}, {pid, token, uid}) do
    IO.inspect(pid)
    IO.inspect(token)
    IO.inspect(uid)
    update |> IO.inspect(label: "webhook genserver handle_cast")
    send_updates([update], pid)

    {:noreply, {pid, token, -1}}
  end

  def handle_info(unknown_message, state) do
    Logger.debug("Polling updates received an unknown message #{inspect(unknown_message)}")

    {:noreply, state}
  end

  defp send_updates(updates, pid) do
    Enum.map(updates, &GenServer.call(pid, {:update, &1}))
  end
end
