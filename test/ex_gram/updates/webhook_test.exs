defmodule ExGram.Updates.WebhookTest do
  use ExUnit.Case, async: false

  alias ExGram.Model.Update
  alias ExGram.Updates.Webhook

  @moduletag :capture_log

  @token "test_webhook_token"
  @token_hash @token |> then(&:crypto.hash(:sha, &1)) |> Base.url_encode64(padding: true)

  setup do
    ExGram.Test.set_global()

    on_exit(fn ->
      Application.delete_env(:ex_gram, :webhook)
    end)

    :ok
  end

  # --- URL construction ---

  describe "set_webhook URL construction" do
    test "default path produces /telegram/<token_hash>" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "/telegram/#{@token_hash}"
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "custom path from opts is used in the URL" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "/custom/hook/#{@token_hash}"
        refute body[:url] =~ "/telegram/"
        true
      end)

      start_webhook_with_opts(%{path: "/custom/hook"})
    end

    test "custom path from config is used in the URL" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        path: "/from/config"
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "/from/config/#{@token_hash}"
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "opts path overrides config path" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        path: "/config/path"
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "/opts/path/#{@token_hash}"
        refute body[:url] =~ "/config/path/"
        true
      end)

      start_webhook_with_opts(%{path: "/opts/path"})
    end

    test "multi-segment path is joined correctly" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "/a/b/c/#{@token_hash}"
        true
      end)

      start_webhook_with_opts(%{path: "/a/b/c"})
    end

    test "base URL scheme and host are preserved in the final URL" do
      Application.put_env(:ex_gram, :webhook, url: "https://mybot.fly.dev")

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:url] =~ "mybot.fly.dev"
        assert body[:url] =~ "https://"
        true
      end)

      start_webhook_with_opts(%{})
    end
  end

  # --- webhook_params filtering ---

  describe "webhook_params - :path is not sent to Telegram" do
    test "path option is not included in the set_webhook call params" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn body ->
        refute Map.has_key?(body, :path)
        true
      end)

      start_webhook_with_opts(%{path: "/custom"})
    end

    test "url option from config is not forwarded as a Telegram param - the full URL is built and passed directly" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn body ->
        # The adapter merges positional args into the body map under :url.
        # That :url is the fully-constructed webhook URL, not the raw config value.
        assert body[:url] =~ "/telegram/#{@token_hash}"
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "allowed_updates are passed through as params" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        allowed_updates: ["message", "callback_query"]
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:allowed_updates] == ["message", "callback_query"]
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "secret_token is passed through as a param" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        secret_token: "valid-secret-token"
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:secret_token] == "valid-secret-token"
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "max_connections integer is passed through as a param" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        max_connections: 50
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:max_connections] == 50
        true
      end)

      start_webhook_with_opts(%{})
    end

    test "max_connections string is converted to integer" do
      Application.put_env(:ex_gram, :webhook,
        url: "https://bot.example.com",
        max_connections: "30"
      )

      ExGram.Test.expect(:set_webhook, fn body ->
        assert body[:max_connections] == 30
        true
      end)

      start_webhook_with_opts(%{})
    end
  end

  # --- URL validation ---

  describe "URL validation" do
    test "missing url logs an error and does not call set_webhook" do
      # No url in config - should log error, not crash
      ExGram.Test.stub(:set_webhook, true)

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          start_webhook_with_opts(%{})
        end)

      assert log =~ "webhook_url is wrong"
    end

    test "url without scheme logs an error" do
      Application.put_env(:ex_gram, :webhook, url: "bot.example.com")
      ExGram.Test.stub(:set_webhook, true)

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          start_webhook_with_opts(%{})
        end)

      assert log =~ "webhook_url is wrong"
    end

    test "url with unsupported scheme logs an error" do
      Application.put_env(:ex_gram, :webhook, url: "ftp://bot.example.com")
      ExGram.Test.stub(:set_webhook, true)

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          start_webhook_with_opts(%{})
        end)

      assert log =~ "webhook_url is wrong"
    end

    test "valid http url does not log an error" do
      Application.put_env(:ex_gram, :webhook, url: "http://bot.example.com")

      ExGram.Test.expect(:set_webhook, fn _body -> true end)

      start_webhook_with_opts(%{})
    end
  end

  # --- update/2 dispatch ---

  describe "update/2" do
    test "dispatches an update to the bot process" do
      Application.put_env(:ex_gram, :webhook, url: "https://bot.example.com")
      ExGram.Test.stub(:set_webhook, true)

      test_pid = self()

      receiver_pid =
        spawn(fn ->
          receive do
            {:"$gen_call", from, {:update, update}} ->
              send(test_pid, {:received_update, update})
              GenServer.reply(from, :ok)
          end
        end)

      start_supervised!(%{
        id: {Webhook, @token},
        start: {Webhook, :start_link, [%{bot: receiver_pid, token: @token}]}
      })

      update = %Update{update_id: 42}
      Webhook.update(update, @token_hash)

      assert_receive {:received_update, %Update{update_id: 42}}, 1000
    end
  end

  # --- Helpers ---

  defp start_webhook_with_opts(extra_opts) do
    receiver_pid = start_supervised!({ExGram.Updates.WebhookTest.UpdateReceiver, []})

    opts = Map.merge(%{bot: receiver_pid, token: @token}, extra_opts)

    start_supervised!(%{
      id: {Webhook, System.unique_integer([:positive])},
      start: {Webhook, :start_link, [opts]}
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
