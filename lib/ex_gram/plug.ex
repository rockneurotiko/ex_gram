defmodule ExGram.Plug do
  @behaviour Plug

  import Plug.Conn
  alias Plug.Conn

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
      case ExGram.Encoder.decode(body, keys: :atoms) do
        {:ok, update} ->
          token_hash = token_hash(conn.path_info)

          struct(ExGram.Model.Update, update)
          |> ExGram.Updates.Webhook.update(token_hash)

          {200, %{ok: true}}

        {:error, _} ->
          {400, %{ok: false}}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, ExGram.Encoder.encode!(message))
    |> halt()
  end

  defp token_hash([path]) when is_binary(path), do: path
  defp token_hash([_ | tl]), do: token_hash(tl)
end
