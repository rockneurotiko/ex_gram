defmodule ExGram.Plug do
  @behaviour Plug

  alias Plug.Conn
  import Plug.Conn
  require Logger

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Conn{method: "POST"} = conn, _) do
    if "telegram" in conn.path_info do
      handle_update(conn)
    else
      conn
    end
  end

  def call(conn, _), do: conn

  defp handle_update(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    {status, message} =
      case get_req_header(conn, "x-telegram-bot-api-secret-token")
           |> check_secret_token() do
        {:ok, _} ->
          handle_update(conn, ExGram.Encoder.decode(body, keys: :atoms))

        {:error, error} ->
          {400, %{error: error}}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, ExGram.Encoder.encode!(message))
    |> halt()
  end

  defp handle_update(conn, {:ok, update}) do
    token_hash = token_hash(conn.path_info)

    struct(ExGram.Model.Update, update)
    |> ExGram.Updates.Webhook.update(token_hash)

    {200, %{ok: true}}
  end

  defp handle_update(_conn, {:error, error}), do: {400, %{error: error}}

  defp check_secret_token([]) do
    Logger.debug(
      "The secret token is not configured in webhook mode. For security purposes, it is recommended to set one."
    )

    {:ok, true}
  end

  defp check_secret_token([secret_token]) do
    config_token = ExGram.Config.get(:ex_gram, :webhook)[:secret_token]

    case {secret_token, config_token} do
      {_secret_token, nil} ->
        message =
          "The secret token exists in the request header but is not configured in the application's settings."

        Logger.error(message)
        {:error, message}

      {secret_token, config_token} when secret_token != config_token ->
        message =
          "The secret token in the request header does not match the one configured in the webhook mode."

        Logger.error(message)
        {:error, message}

      {secret_token, config_token} when secret_token == config_token ->
        {:ok, true}
    end
  end

  defp token_hash([path]) when is_binary(path), do: path
  defp token_hash([_ | tl]), do: token_hash(tl)
end
