defmodule ExGram.Updates.Webhook do
  @moduledoc """
  Updates implementation that uses webhook method
  """

  use GenServer

  require Logger

  @posible_updates %ExGram.Model.Update{}
                   |> Map.keys()
                   |> List.delete(:__struct__)
                   |> List.delete(:update_id)

  def update(update, token_hash) do
    token_hash
    |> process_name()
    |> GenServer.cast({:update, update})
  end

  def start_link(%{bot: pid, token: token} = opts) do
    opts = Map.drop(opts, [:bot, :token])

    name =
      token
      |> token_hash()
      |> process_name()

    GenServer.start_link(__MODULE__, {:ok, pid, token, opts}, name: name)
  end

  def init({:ok, pid, token, opts}) do
    set_webhook(token, opts)

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

  defp process_name(token_hash), do: Module.concat(__MODULE__, token_hash)

  defp token_hash(token) do
    :sha
    |> :crypto.hash(token)
    |> Base.url_encode64(padding: true)
  end

  defp set_webhook(token, opts) do
    opts =
      opts
      |> Map.take([
        :certificate,
        :url,
        :max_connections,
        :allowed_updates,
        :secret_token,
        :drop_pending_updates,
        :ip_address
      ])
      |> Keyword.new()

    config = :ex_gram |> ExGram.Config.get(:webhook, []) |> Keyword.merge(opts)
    params = webhook_params(config)

    webhook_path = Keyword.get(opts, :webhook_path, "telegram")

    case valid_url(config[:url]) do
      {:ok, webhook_url} ->
        params = Keyword.put(params, :token, token)
        url = "#{webhook_url}/#{webhook_path}/#{token_hash(token)}"
        {:ok, true} = ExGram.set_webhook(url, params)

      {:error, error} ->
        Logger.error(
          "The webhook_url is wrong with reason: #{inspect(error)}. Please manually set the webhook using this method: https://core.telegram.org/bots/api#setwebhook or edit the config file!"
        )
    end
  end

  defp valid_url(nil), do: {:error, :not_set}
  defp valid_url(url), do: url |> URI.parse() |> do_valid_url()

  defp do_valid_url(%URI{scheme: nil}), do: {:error, :scheme_not_set}

  defp do_valid_url(%URI{scheme: scheme}) when scheme not in ["http", "https"], do: {:error, :scheme_is_wrong}

  defp do_valid_url(%URI{host: nil}), do: {:error, :host_not_set}

  defp do_valid_url(%URI{scheme: scheme, host: host, port: port}), do: {:ok, "#{scheme}://#{host}:#{port}"}

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

  defp webhook_params([{:max_connections, max_connections} | tl], params) when is_integer(max_connections) do
    webhook_params(tl, [{:max_connections, max_connections} | params])
  end

  defp webhook_params([{:max_connections, max_connections} | tl], params) do
    webhook_params(tl, [{:max_connections, String.to_integer(max_connections)} | params])
  end

  defp webhook_params([{:allowed_updates, allowed_updates} | tl], params) when is_list(allowed_updates) do
    allowed_updates =
      allowed_updates
      |> Enum.map(fn update ->
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
          "The secret_token must be between 1 to 256 characters. Only characters A-Z, a-z, 0-9, _ and - are allowed."
        )

        webhook_params(tl, params)
    end
  end

  defp webhook_params([{key, value} | tl], params), do: webhook_params(tl, [{key, value} | params])
end
