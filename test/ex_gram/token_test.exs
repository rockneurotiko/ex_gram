defmodule ExGram.TokenTest do
  use ExUnit.Case, async: false

  alias ExGram.Token

  setup do
    # Save the original token and restore it after the test
    original_token = Application.get_env(:ex_gram, :token)

    on_exit(fn ->
      if original_token do
        Application.put_env(:ex_gram, :token, original_token)
      else
        Application.delete_env(:ex_gram, :token)
      end
    end)

    # Clear any existing config for this test
    Application.delete_env(:ex_gram, :token)
    :ok
  end

  describe "fetch/1" do
    test "returns nil when no token is configured" do
      assert nil == Token.fetch()
    end

    test "returns token from application config" do
      Application.put_env(:ex_gram, :token, "config_token_123")
      assert "config_token_123" == Token.fetch()
    end

    test "returns explicit token when provided" do
      assert "explicit_token" == Token.fetch(token: "explicit_token")
    end

    test "explicit token takes precedence over config" do
      Application.put_env(:ex_gram, :token, "config_token")
      assert "explicit_token" == Token.fetch(token: "explicit_token")
    end

    test "fetches token from registry when bot name is provided" do
      bot_name = :test_bot_token
      token = "registry_token_123"

      # Register a bot with token
      {:ok, _} = Registry.register(Registry.ExGram, bot_name, token)

      assert token == Token.fetch(bot: bot_name)
    end

    test "returns nil and logs warning when bot is not registered" do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          assert nil == Token.fetch(bot: :non_existent_bot)
        end)

      assert log =~ "not registered"
    end

    test "returns nil and logs warning when bot has no token" do
      import ExUnit.CaptureLog

      bot_name = :bot_without_token
      # Register bot with non-string value
      {:ok, _} = Registry.register(Registry.ExGram, bot_name, %{no: :token})

      log =
        capture_log(fn ->
          assert nil == Token.fetch(bot: bot_name)
        end)

      assert log =~ "does not have a token"
    end

    test "raises error when custom registry does not exist" do
      # For this test to work properly, a custom registry would need to be created
      # When a non-existent registry is provided, it should raise an ArgumentError
      bot_name = :custom_registry_bot

      assert_raise ArgumentError, fn ->
        Token.fetch(bot: bot_name, registry: :NonExistentRegistry)
      end
    end
  end
end
