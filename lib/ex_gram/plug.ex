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
    token_hash = token_hash(conn.path_info)

    {:ok, body, conn} = Plug.Conn.read_body(conn)
    {:ok, update} = Jason.decode(body, keys: :atoms)
    update = struct(ExGram.Model.Update, update)

    ExGram.Updates.Webhook.update(token_hash, update)

    conn
    |> send_resp(200, "")
    |> halt()
  end

  defp token_hash([path]) when is_binary(path), do: path
  defp token_hash([_ | tl]), do: token_hash(tl)
end
