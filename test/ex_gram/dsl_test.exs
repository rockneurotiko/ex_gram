defmodule ExGram.DslTest do
  use ExUnit.Case, async: true

  alias ExGram.Dsl
  alias ExGram.Model.Chat
  alias ExGram.Model.InlineKeyboardMarkup
  alias ExGram.Model.Message
  alias ExGram.Model.Update
  alias ExGram.Model.User

  describe "extract_user/1" do
    test "extracts user from update with from field" do
      user = %User{id: 123, username: "testuser"}
      update = %{from: user}

      assert {:ok, ^user} = Dsl.extract_user(update)
    end

    test "extracts user from message" do
      user = %User{id: 456, username: "msguser"}
      message = %Message{from: user}
      update = %Update{message: message}

      assert {:ok, ^user} = Dsl.extract_user(update)
    end

    test "extracts user from edited_message" do
      user = %User{id: 789, username: "editor"}
      message = %Message{from: user}
      update = %Update{edited_message: message}

      assert {:ok, ^user} = Dsl.extract_user(update)
    end

    test "extracts user from callback_query" do
      user = %User{id: 999, username: "callback"}
      callback = %{from: user}
      update = %Update{callback_query: callback}

      assert {:ok, ^user} = Dsl.extract_user(update)
    end

    test "returns error when no user found" do
      update = %Update{}
      assert :error = Dsl.extract_user(update)
    end
  end

  describe "extract_chat/1" do
    test "extracts chat from update with chat field" do
      chat = %Chat{id: 123, type: "private"}
      update = %{chat: chat}

      assert {:ok, ^chat} = Dsl.extract_chat(update)
    end

    test "extracts chat from message" do
      chat = %Chat{id: 456, type: "group"}
      message = %Message{chat: chat}
      update = %Update{message: message}

      assert {:ok, ^chat} = Dsl.extract_chat(update)
    end

    test "extracts chat from edited_message" do
      chat = %Chat{id: 789, type: "supergroup"}
      message = %Message{chat: chat}
      update = %Update{edited_message: message}

      assert {:ok, ^chat} = Dsl.extract_chat(update)
    end

    test "returns error when no chat found" do
      update = %Update{}
      assert :error = Dsl.extract_chat(update)
    end
  end

  describe "extract_id/1" do
    test "extracts chat id when chat is present" do
      chat = %Chat{id: 12_345}
      message = %Message{chat: chat}
      update = %Update{message: message}

      assert 12_345 = Dsl.extract_id(update)
    end

    test "extracts user id when only user is present" do
      user = %User{id: 67_890}
      update = %{from: user}

      assert 67_890 = Dsl.extract_id(update)
    end

    test "returns -1 when neither chat nor user found" do
      update = %Update{}
      assert -1 = Dsl.extract_id(update)
    end
  end

  describe "extract_update_type/1" do
    test "returns :message for message update" do
      update = %Update{message: %Message{}}
      assert {:ok, :message} = Dsl.extract_update_type(update)
    end

    test "returns :edited_message for edited message" do
      update = %Update{edited_message: %Message{}}
      assert {:ok, :edited_message} = Dsl.extract_update_type(update)
    end

    test "returns :callback_query for callback" do
      update = %Update{callback_query: %{}}
      assert {:ok, :callback_query} = Dsl.extract_update_type(update)
    end

    test "returns :inline_query for inline query" do
      update = %Update{inline_query: %{}}
      assert {:ok, :inline_query} = Dsl.extract_update_type(update)
    end

    test "returns error for empty update" do
      update = %Update{}
      assert :error = Dsl.extract_update_type(update)
    end
  end

  describe "extract_message_type/1" do
    test "returns :text for text message" do
      message = %Message{text: "hello"}
      assert {:ok, :text} = Dsl.extract_message_type(message)
    end

    test "returns :photo for photo message" do
      message = %Message{photo: [%{}]}
      assert {:ok, :photo} = Dsl.extract_message_type(message)
    end

    test "returns :document for document message" do
      message = %Message{document: %{}}
      assert {:ok, :document} = Dsl.extract_message_type(message)
    end

    test "returns :video for video message" do
      message = %Message{video: %{}}
      assert {:ok, :video} = Dsl.extract_message_type(message)
    end

    test "returns :audio for audio message" do
      message = %Message{audio: %{}}
      assert {:ok, :audio} = Dsl.extract_message_type(message)
    end

    test "returns :sticker for sticker message" do
      message = %Message{sticker: %{}}
      assert {:ok, :sticker} = Dsl.extract_message_type(message)
    end

    test "returns :location for location message" do
      message = %Message{location: %{}}
      assert {:ok, :location} = Dsl.extract_message_type(message)
    end

    test "returns error for message without type" do
      message = %Message{}
      assert :error = Dsl.extract_message_type(message)
    end
  end

  describe "extract_message_id/1" do
    test "extracts message_id from message" do
      message = %Message{message_id: 42}
      assert 42 = Dsl.extract_message_id(message)
    end

    test "extracts message_id from update with message" do
      message = %Message{message_id: 100}
      update = %{message: message}
      assert 100 = Dsl.extract_message_id(update)
    end

    test "returns error when no message_id found" do
      assert :error = Dsl.extract_message_id(%{})
    end
  end

  describe "create_inline/1" do
    test "creates inline keyboard markup with empty rows" do
      result = Dsl.create_inline([])
      assert %InlineKeyboardMarkup{inline_keyboard: []} = result
    end

    test "creates inline keyboard markup with single button" do
      buttons = [[text: "Button 1", callback_data: "btn1"]]
      result = Dsl.create_inline([buttons])

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = result
      assert [button] = row
      assert %ExGram.Model.InlineKeyboardButton{text: "Button 1", callback_data: "btn1"} = button
    end

    test "creates inline keyboard markup with multiple rows" do
      buttons = [
        [text: "Button 1", callback_data: "btn1"],
        [text: "Button 2", callback_data: "btn2"]
      ]

      result = Dsl.create_inline([buttons, buttons])

      assert %InlineKeyboardMarkup{inline_keyboard: rows} = result
      assert length(rows) == 2
    end

    test "creates inline keyboard with multiple buttons per row" do
      row1 = [
        [text: "A", callback_data: "a"],
        [text: "B", callback_data: "b"]
      ]

      result = Dsl.create_inline([row1])

      assert %InlineKeyboardMarkup{inline_keyboard: [buttons]} = result
      assert length(buttons) == 2
    end
  end

  describe "extract_callback_id/1" do
    test "extracts callback id from callback_query" do
      callback = %{id: "callback_123", data: "some_data"}
      assert "callback_123" = Dsl.extract_callback_id(callback)
    end

    test "extracts callback id from update with callback_query" do
      callback = %{id: "callback_456", data: "data"}
      update = %{callback_query: callback}
      assert "callback_456" = Dsl.extract_callback_id(update)
    end

    test "returns the id when passed directly" do
      assert "direct_id" = Dsl.extract_callback_id("direct_id")
    end

    test "returns error for invalid input" do
      assert :error = Dsl.extract_callback_id(%{})
    end
  end
end
