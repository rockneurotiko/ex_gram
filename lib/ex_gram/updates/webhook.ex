defmodule ExGram.Updates.Webhook do
  @moduledoc """
  Updates implementation that uses webhook method
  """

  use GenServer
  require Logger

  @posible_updates Map.keys(%ExGram.Model.Update{})
                   |> List.delete(:__struct__)
                   |> List.delete(:update_id)

  def update(update, token_hash) do
    Module.concat(__MODULE__, token_hash)
    |> GenServer.cast({:update, update})
  end

  def start_link({:bot, pid, :token, token}) do
    name = Module.concat(__MODULE__, token_hash(token))

    GenServer.start_link(__MODULE__, {:ok, pid, token}, name: name)
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
    config = ExGram.Config.get(:ex_gram, :webhook)
    params = webhook_params(config)

    case config[:url] do
      webhook_url when is_binary(webhook_url) ->
        webhook_url =
          webhook_url
          |> Plug.Router.Utils.split()

        case ExGram.set_webhook(
               "https://#{webhook_url}/telegram/#{token_hash(token)}",
               [{:token, token} | params]
             ) do
          {:ok, _} -> nil
          {:error, error} -> Logger.error("Could not set the webhook: #{inspect(error)}")
        end

      nil ->
        Logger.warning(
          "The webhook_url is not set in the configuration. Please manually set the webhook using this method: https://core.telegram.org/bots/api#setwebhook"
        )
    end
  end

  defp webhook_params(_, params \\ [])
  defp webhook_params([], params), do: params

  defp webhook_params([{:certificate, path} | tl], params) do
    case File.read(path) do
      {:ok, _} ->
        webhook_params(tl, [{:certificate, {:file, path}} | params])

      {:error, reason} ->
        Logger.error("Could not read the certificate file from #{path}: #{inspect(reason)}")

        webhook_params(tl, params)
    end
  end

  defp webhook_params([{:url, _} | tl], params), do: webhook_params(tl, params)

  defp webhook_params([{:max_connections, max_connections} | tl], params)
       when is_integer(max_connections),
       do: webhook_params(tl, [{:max_connections, max_connections} | params])

  defp webhook_params([{:max_connections, max_connections} | tl], params),
    do: webhook_params(tl, [{:max_connections, String.to_integer(max_connections)} | params])

  defp webhook_params([{:allowed_updates, allowed_updates} | tl], params)
       when is_list(allowed_updates) do
    allowed_updates =
      Enum.map(allowed_updates, fn update ->
        if String.to_atom(update) in @posible_updates do
          update
        else
          Logger.error("The update #{update} is not a valid update")

          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    webhook_params(tl, [{:allowed_updates, allowed_updates} | params])
  end

  @secret_token_length 1..256
  @secret_token_format ~r/^[A-Za-z0-9_-]+$/
  defp webhook_params([{:secret_token, secret_token} | tl], params) do
    with true <- String.length(secret_token) in @secret_token_length,
         true <- String.match?(secret_token, @secret_token_format) do
      webhook_params(tl, [{:secret_token, secret_token} | params])
    else
      _ ->
        Logger.error(
          "The secret_token must be between #{@secret_token_length} characters. Only characters A-Z, a-z, 0-9, _ and - are allowed."
        )

        webhook_params(tl, params)
    end
  end

  defp webhook_params([{key, value} | tl], params),
    do: webhook_params(tl, [{key, value} | params])
end
