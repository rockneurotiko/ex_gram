defmodule ExGram.Middleware.IgnoreUsernameTest do
  use ExUnit.Case, async: true

  alias ExGram.Cnt
  alias ExGram.Middleware.IgnoreUsername
  alias ExGram.Model.Message
  alias ExGram.Model.Update
  alias ExGram.Model.User

  describe "call/2" do
    test "removes bot username from command" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/start@my_bot"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/start"}}} = result
    end

    test "removes bot username from command with arguments" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/search@my_bot hello world"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/search hello world"}}} = result
    end

    test "keeps command unchanged when no username suffix" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/start"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/start"}}} = result
    end

    test "keeps command unchanged when different bot username" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/start@other_bot"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/start@other_bot"}}} = result
    end

    test "handles command with multiple @ symbols" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/email@my_bot user@example.com"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/email user@example.com"}}} = result
    end

    test "returns cnt unchanged when message is not a command" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "Hello, this is not a command"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert result == cnt
    end

    test "returns cnt unchanged when text is nil" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: nil}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert result == cnt
    end

    test "returns cnt unchanged when message is nil" do
      bot_info = %User{username: "my_bot"}
      update = %Update{message: nil}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert result == cnt
    end

    test "returns cnt unchanged when bot_info username is nil" do
      bot_info = %User{username: nil}
      message = %Message{text: "/start@my_bot"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert result == cnt
    end

    test "handles empty command after slash" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{} = result
    end

    test "preserves multiple spaces in arguments" do
      bot_info = %User{username: "my_bot"}
      message = %Message{text: "/cmd@my_bot arg1  arg2   arg3"}
      update = %Update{message: message}
      cnt = %Cnt{bot_info: bot_info, update: update}

      result = IgnoreUsername.call(cnt, [])

      assert %Cnt{update: %Update{message: %Message{text: "/cmd arg1  arg2   arg3"}}} = result
    end
  end
end
