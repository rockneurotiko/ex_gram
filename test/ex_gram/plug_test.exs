defmodule ExGram.PlugTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias ExGram.Plug, as: ExGramPlug
  alias ExGram.Updates.Webhook

  @moduletag :capture_log

  @token "test_plug_token"
  @token_hash @token |> then(&:crypto.hash(:sha, &1)) |> Base.url_encode64(padding: true)

  @update_json ~s({"update_id":1,"message":{"message_id":1,"date":0,"chat":{"id":1,"type":"private"},"from":{"id":1,"first_name":"Test","is_bot":false}}})

  setup do
    ExGram.Test.set_global()

    on_exit(fn ->
      Application.delete_env(:ex_gram, :webhook)
    end)

    :ok
  end

  # --- init/1 ---

  describe "init/1" do
    test "defaults to /telegram when no opts or config" do
      opts = ExGramPlug.init([])
      assert opts[:path_parts] == ["telegram"]
    end

    test "uses custom path from opts" do
      opts = ExGramPlug.init(path: "/custom/webhook")
      assert opts[:path_parts] == ["custom", "webhook"]
    end

    test "uses single-segment path from opts" do
      opts = ExGramPlug.init(path: "/mybot")
      assert opts[:path_parts] == ["mybot"]
    end

    test "reads path from application config when no opts given" do
      Application.put_env(:ex_gram, :webhook, path: "/from/config")

      opts = ExGramPlug.init([])
      assert opts[:path_parts] == ["from", "config"]
    end

    test "opts override application config" do
      Application.put_env(:ex_gram, :webhook, path: "/from/config")

      opts = ExGramPlug.init(path: "/from/opts")
      assert opts[:path_parts] == ["from", "opts"]
    end
  end

  # --- Non-POST requests ---

  describe "non-POST requests" do
    test "GET request passes through unchanged" do
      opts = ExGramPlug.init([])
      conn = :get |> conn("/telegram/#{@token_hash}") |> ExGramPlug.call(opts)

      refute conn.halted
      assert conn.status == nil
    end

    test "PUT request passes through unchanged" do
      opts = ExGramPlug.init([])
      conn = :put |> conn("/telegram/#{@token_hash}") |> ExGramPlug.call(opts)

      refute conn.halted
    end
  end

  # --- Path matching ---

  describe "path matching - POST requests" do
    test "non-matching path prefix passes through" do
      opts = ExGramPlug.init([])
      conn = :post |> conn("/wrong/path/#{@token_hash}") |> ExGramPlug.call(opts)

      refute conn.halted
    end

    test "path missing token hash segment passes through" do
      opts = ExGramPlug.init([])
      conn = :post |> conn("/telegram") |> ExGramPlug.call(opts)

      refute conn.halted
    end

    test "path with extra segment beyond token hash passes through" do
      opts = ExGramPlug.init([])
      conn = :post |> conn("/telegram/#{@token_hash}/extra") |> ExGramPlug.call(opts)

      refute conn.halted
    end

    test "root path passes through" do
      opts = ExGramPlug.init([])
      conn = :post |> conn("/") |> ExGramPlug.call(opts)

      refute conn.halted
    end

    test "default /telegram path is not matched when custom path is configured" do
      opts = ExGramPlug.init(path: "/custom/hook")
      conn = :post |> conn("/telegram/#{@token_hash}") |> ExGramPlug.call(opts)

      refute conn.halted
    end

    test "custom path with correct token hash is matched" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init(path: "/custom/hook")
      conn = build_update_conn("/custom/hook/#{@token_hash}", @update_json)

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 200
    end

    test "multi-segment custom path is matched correctly" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init(path: "/a/b/c")
      conn = build_update_conn("/a/b/c/#{@token_hash}", @update_json)

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 200
    end
  end

  # --- Secret token ---

  describe "secret token validation" do
    test "no header and no config accepts the request" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])
      conn = build_update_conn("/telegram/#{@token_hash}", @update_json)

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 200
    end

    test "matching secret token accepts the request" do
      Application.put_env(:ex_gram, :webhook, secret_token: "my-secret")
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])

      conn =
        "/telegram/#{@token_hash}"
        |> build_update_conn(@update_json)
        |> put_req_header("x-telegram-bot-api-secret-token", "my-secret")

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 200
    end

    test "mismatched secret token returns 400" do
      Application.put_env(:ex_gram, :webhook, secret_token: "expected-secret")
      opts = ExGramPlug.init([])

      conn =
        "/telegram/#{@token_hash}"
        |> build_update_conn(@update_json)
        |> put_req_header("x-telegram-bot-api-secret-token", "wrong-secret")

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 400
      assert conn.resp_body =~ "does not match"
    end

    test "secret token header present but not configured returns 400" do
      opts = ExGramPlug.init([])

      conn =
        "/telegram/#{@token_hash}"
        |> build_update_conn(@update_json)
        |> put_req_header("x-telegram-bot-api-secret-token", "some-token")

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 400
      assert conn.resp_body =~ "not configured"
    end
  end

  # --- Update handling ---

  describe "update handling" do
    test "valid update body returns 200 with ok: true" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])
      conn = build_update_conn("/telegram/#{@token_hash}", @update_json)

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~s("ok":true)
    end

    test "response content-type is application/json" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])
      conn = build_update_conn("/telegram/#{@token_hash}", @update_json)

      conn = ExGramPlug.call(conn, opts)

      assert conn |> get_resp_header("content-type") |> hd() =~ "application/json"
    end

    test "valid JSON body that is not a valid Telegram update returns 400" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])
      # A JSON array decodes to a list, which cast/2 rejects as not a valid Update
      conn = build_update_conn("/telegram/#{@token_hash}", ~s([1,2,3]))

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 400
      assert {:ok, body} = Jason.decode(conn.resp_body)
      assert body["ok"] == false
      assert body["error"] =~ "valid Telegram update"
    end

    test "invalid JSON body returns 400 with a JSON-encoded error message" do
      start_webhook_for_token(@token)
      opts = ExGramPlug.init([])
      conn = build_update_conn("/telegram/#{@token_hash}", "not valid json{")

      conn = ExGramPlug.call(conn, opts)

      assert conn.halted
      assert conn.status == 400
      assert conn |> get_resp_header("content-type") |> hd() =~ "application/json"
      assert {:ok, body} = Jason.decode(conn.resp_body)
      assert is_binary(body["error"])
    end
  end

  # --- Helpers ---

  defp build_update_conn(path, body) do
    :post
    |> conn(path, body)
    |> put_req_header("content-type", "application/json")
  end

  # Starts a Webhook GenServer for the given token so the plug can dispatch
  # updates to it. A minimal process acts as the bot receiver.
  defp start_webhook_for_token(token) do
    existing = Application.get_env(:ex_gram, :webhook, [])
    Application.put_env(:ex_gram, :webhook, Keyword.put(existing, :url, "https://test.example.com"))
    ExGram.Test.stub(:set_webhook, true)

    receiver_pid = start_supervised!({ExGram.PlugTest.UpdateReceiver, []})

    start_supervised!(%{
      id: {Webhook, token},
      start: {Webhook, :start_link, [%{bot: receiver_pid, token: token}]}
    })
  end

  defmodule UpdateReceiver do
    @moduledoc false
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, [])
    def init(_), do: {:ok, %{}}

    def handle_call({:update, _update}, _from, state), do: {:reply, :ok, state}
  end
end
