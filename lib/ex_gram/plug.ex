defmodule ExGram.Plug do
  @behaviour Plug
  @allowed_methods ~w(POST)

  import Plug.Conn
  alias Plug.Conn

  @impl true
  def init(opts) do
    %{
      headers: Keyword.get(opts, :headers, %{}),
      content_types: Keyword.get(opts, :content_types, %{}),
      at: ExGram.Config.get(:ex_gram, :webhook_path) |> Plug.Router.Utils.split()
    }
  end

  @impl true
  def call(
        conn = %Conn{method: meth},
        %{at: at}
      )
      when meth in @allowed_methods do
    if hd(at) in conn.path_info do
      serve_update(conn)
    else
      conn
    end
  end

  def call(conn, _options) do
    conn
  end

  defp serve_update(conn) do
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
