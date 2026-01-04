defmodule ExGram.FileTest do
  use ExUnit.Case, async: false

  alias ExGram.File
  alias ExGram.Model.File, as: TelegramFile

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

  describe "file_url/2" do
    test "generates correct URL with token from config" do
      Application.put_env(:ex_gram, :token, "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11")
      file = %TelegramFile{file_path: "photos/file_1.jpg"}

      url = File.file_url(file)

      assert url ==
               "https://api.telegram.org/file/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/photos/file_1.jpg"
    end

    test "generates correct URL with explicit token" do
      file = %TelegramFile{file_path: "documents/file_2.pdf"}
      token = "987654:XYZ-UVW9876abc-def12Q3r4t567yz89"

      url = File.file_url(file, token: token)

      assert url == "https://api.telegram.org/file/bot#{token}/documents/file_2.pdf"
    end

    test "generates correct URL with token from registry" do
      bot_name = :file_test_bot
      token = "111222:AAA-BBB1111ccc-ddd22E3e4e567fg78"

      {:ok, _} = Registry.register(Registry.ExGram, bot_name, token)

      file = %TelegramFile{file_path: "videos/video_1.mp4"}
      url = File.file_url(file, bot: bot_name)

      assert url == "https://api.telegram.org/file/bot#{token}/videos/video_1.mp4"
    end

    test "handles file paths with subdirectories" do
      Application.put_env(:ex_gram, :token, "test_token")
      file = %TelegramFile{file_path: "path/to/deep/file.txt"}

      url = File.file_url(file)

      assert url == "https://api.telegram.org/file/bottest_token/path/to/deep/file.txt"
    end

    test "handles file paths with special characters" do
      Application.put_env(:ex_gram, :token, "test_token")
      file = %TelegramFile{file_path: "files/file-with_special.chars123.jpg"}

      url = File.file_url(file)

      assert url == "https://api.telegram.org/file/bottest_token/files/file-with_special.chars123.jpg"
    end

    test "explicit token takes precedence over config" do
      Application.put_env(:ex_gram, :token, "config_token")
      file = %TelegramFile{file_path: "test.jpg"}
      explicit_token = "explicit_token"

      url = File.file_url(file, token: explicit_token)

      assert url == "https://api.telegram.org/file/botexplicit_token/test.jpg"
    end
  end
end
