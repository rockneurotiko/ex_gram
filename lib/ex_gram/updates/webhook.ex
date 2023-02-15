defmodule ExGram.Updates.Webhook do
  @moduledoc """
  Updates implementation that uses webhook method
  """

  use GenServer
  require Logger

  def update(token_hash, update) do
    token_hash =
      token_hash
      |> String.to_atom()

    GenServer.cast(token_hash, {:update, update})
  end

  def start_link({:bot, pid, :token, token}) do
    token_hash =
      token_hash(token)
      |> String.to_atom()

    GenServer.start_link(__MODULE__, {:ok, pid, token}, name: token_hash)
  end

  def init({:ok, pid, token}) do
    set_webhook(token)

    {:ok, {pid, token}}
  end

  def handle_cast({:update, update}, {pid, token}) do
    GenServer.call(pid, {:update, update})

    {:noreply, {pid, token}}
  end

  def handle_info(unknown_message, state) do
    Logger.debug("Webhook updates received an unknown message #{inspect(unknown_message)}")

    {:noreply, state}
  end

  defp token_hash(token) do
    :crypto.hash(:sha, token)
    |> Base.url_encode64(padding: true)
  end

  defp set_webhook(token) do
    case ExGram.Config.get(:ex_gram, :webhook_url) do
      webhook_url when is_binary(webhook_url) ->
        webhook_url =
          webhook_url
          |> Plug.Router.Utils.split()

        ExGram.set_webhook(
          "https://#{webhook_url}/telegram/#{token_hash(token)}",
          token: token
        )

      nil ->
        Logger.warning(
          "webhook_url is not set in config. Please set webhook manual by this method: https://core.telegram.org/bots/api#setwebhook"
        )
    end
  end
end
