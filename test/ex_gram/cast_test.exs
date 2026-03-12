defmodule ExGram.CastTest do
  use ExUnit.Case, async: true

  alias ExGram.Cast
  alias ExGram.Model

  doctest Cast

  # ---------------------------------------------------------------------------
  # Primitive types
  # ---------------------------------------------------------------------------

  describe "primitive :integer" do
    test "casts an integer" do
      assert {:ok, 42} = Cast.cast(42, :integer)
    end

    test "rejects a non-integer" do
      assert {:error, %ExGram.Error{message: "Expected integer, got: \"42\""}} =
               Cast.cast("42", :integer)
    end
  end

  describe "primitive :float" do
    test "casts a float" do
      assert {:ok, 3.14} = Cast.cast(3.14, :float)
    end

    test "rejects a non-float" do
      assert {:error, %ExGram.Error{message: "Expected float, got: 3"}} =
               Cast.cast(3, :float)
    end
  end

  describe "primitive :string" do
    test "casts a binary string" do
      assert {:ok, "hello"} = Cast.cast("hello", :string)
    end

    test "rejects a non-string" do
      assert {:error, %ExGram.Error{message: "Expected string, got: 123"}} =
               Cast.cast(123, :string)
    end
  end

  describe "primitive :boolean" do
    test "casts true" do
      assert {:ok, true} = Cast.cast(true, :boolean)
    end

    test "casts false" do
      assert {:ok, false} = Cast.cast(false, :boolean)
    end

    test "rejects a non-boolean" do
      assert {:error, %ExGram.Error{message: "Expected boolean, got: 1"}} =
               Cast.cast(1, :boolean)
    end
  end

  describe "literal true type" do
    test "casts true" do
      assert {:ok, true} = Cast.cast(true, true)
    end

    test "rejects false" do
      assert {:error, _} = Cast.cast(false, true)
    end
  end

  describe "nil passthrough" do
    test "nil value with any type returns nil" do
      assert {:ok, nil} = Cast.cast(nil, :integer)
      assert {:ok, nil} = Cast.cast(nil, :string)
      assert {:ok, nil} = Cast.cast(nil, Model.User)
    end

    test "nil type passes value through" do
      assert {:ok, 42} = Cast.cast(42, nil)
      assert {:ok, "hello"} = Cast.cast("hello", nil)
    end
  end

  # ---------------------------------------------------------------------------
  # :file and :file_content types
  # ---------------------------------------------------------------------------

  describe ":file type" do
    test "casts a string file_id or URL" do
      assert {:ok, "AgACAgIAAxkBAAIBq2"} = Cast.cast("AgACAgIAAxkBAAIBq2", :file)
      assert {:ok, "https://example.com/photo.jpg"} = Cast.cast("https://example.com/photo.jpg", :file)
    end

    test "casts a {:file, path} tuple" do
      assert {:ok, {:file, "/tmp/photo.jpg"}} = Cast.cast({:file, "/tmp/photo.jpg"}, :file)
    end

    test "casts a {:file_content, content, name} tuple" do
      assert {:ok, {:file_content, "binary_data", "photo.jpg"}} =
               Cast.cast({:file_content, "binary_data", "photo.jpg"}, :file)
    end

    test "rejects an integer" do
      assert {:error, %ExGram.Error{message: "Expected file, got: 123"}} =
               Cast.cast(123, :file)
    end

    test "rejects a map" do
      assert {:error, _} = Cast.cast(%{path: "file.jpg"}, :file)
    end
  end

  describe ":file_content type" do
    test "casts a {:file_content, content, name} tuple" do
      assert {:ok, {:file_content, "binary_data", "doc.pdf"}} =
               Cast.cast({:file_content, "binary_data", "doc.pdf"}, :file_content)
    end

    test "rejects a plain string" do
      assert {:error, %ExGram.Error{message: "Expected file_content, got: \"path.pdf\""}} =
               Cast.cast("path.pdf", :file_content)
    end

    test "rejects a {:file, path} tuple" do
      assert {:error, _} = Cast.cast({:file, "/tmp/doc.pdf"}, :file_content)
    end
  end

  # ---------------------------------------------------------------------------
  # Array types
  # ---------------------------------------------------------------------------

  describe "array of primitives" do
    test "casts an array of integers" do
      assert {:ok, [1, 2, 3]} = Cast.cast([1, 2, 3], {:array, :integer})
    end

    test "casts an array of strings" do
      assert {:ok, ["a", "b"]} = Cast.cast(["a", "b"], {:array, :string})
    end

    test "casts an empty array" do
      assert {:ok, []} = Cast.cast([], {:array, :integer})
    end

    test "errors on wrong element type" do
      assert {:error, %ExGram.Error{message: "Expected integer, got: \"x\""}} =
               Cast.cast(["x"], {:array, :integer})
    end
  end

  describe "array via single-element list type" do
    test "casts a list using [type] notation" do
      assert {:ok, [1, 2, 3]} = Cast.cast([1, 2, 3], [:integer])
    end

    test "casts empty list" do
      assert {:ok, []} = Cast.cast([], [:string])
    end
  end

  describe "nested arrays" do
    test "casts {:array, {:array, t}}" do
      input = [[1, 2], [3, 4]]
      assert {:ok, [[1, 2], [3, 4]]} = Cast.cast(input, {:array, {:array, :integer}})
    end

    test "casts array of arrays of model structs (InlineKeyboardMarkup)" do
      input = %{
        inline_keyboard: [
          [%{text: "Yes", callback_data: "yes"}, %{text: "No", callback_data: "no"}],
          [%{text: "Cancel", callback_data: "cancel"}]
        ]
      }

      assert {:ok, %Model.InlineKeyboardMarkup{inline_keyboard: [[btn1, btn2], [btn3]]}} =
               Cast.cast(input, Model.InlineKeyboardMarkup)

      assert %Model.InlineKeyboardButton{text: "Yes", callback_data: "yes"} = btn1
      assert %Model.InlineKeyboardButton{text: "No", callback_data: "no"} = btn2
      assert %Model.InlineKeyboardButton{text: "Cancel", callback_data: "cancel"} = btn3
    end

    test "casts UserProfilePhotos with nested photo arrays" do
      input = %{
        total_count: 2,
        photos: [
          [%{file_id: "f1", file_unique_id: "u1", width: 100, height: 100}],
          [%{file_id: "f2", file_unique_id: "u2", width: 200, height: 200}]
        ]
      }

      assert {:ok, %Model.UserProfilePhotos{total_count: 2, photos: [[photo1], [photo2]]}} =
               Cast.cast(input, Model.UserProfilePhotos)

      assert %Model.PhotoSize{file_id: "f1", width: 100} = photo1
      assert %Model.PhotoSize{file_id: "f2", width: 200} = photo2
    end
  end

  # ---------------------------------------------------------------------------
  # Simple model structs (primitives only)
  # ---------------------------------------------------------------------------

  describe "simple model: MessageId" do
    test "casts a message id" do
      assert {:ok, %Model.MessageId{message_id: 123}} =
               Cast.cast(%{message_id: 123}, Model.MessageId)
    end

    test "errors when field has wrong type" do
      assert {:error, _} = Cast.cast(%{message_id: "not_an_int"}, Model.MessageId)
    end
  end

  describe "simple model: Location (floats + integers)" do
    test "casts all float and integer fields" do
      input = %{
        latitude: 51.5074,
        longitude: -0.1278,
        horizontal_accuracy: 10.5,
        live_period: 300,
        heading: 90,
        proximity_alert_radius: 500
      }

      assert {:ok, %Model.Location{} = loc} = Cast.cast(input, Model.Location)
      assert loc.latitude == 51.5074
      assert loc.longitude == -0.1278
      assert loc.horizontal_accuracy == 10.5
      assert loc.live_period == 300
    end

    test "casts with only required fields (optional fields become nil)" do
      assert {:ok, %Model.Location{latitude: 48.8566, longitude: 2.3522, live_period: nil}} =
               Cast.cast(%{latitude: 48.8566, longitude: 2.3522}, Model.Location)
    end

    test "errors when float field receives integer" do
      assert {:error, _} = Cast.cast(%{latitude: 51, longitude: -0.1278}, Model.Location)
    end
  end

  describe "empty marker struct: ForumTopicClosed" do
    test "casts an empty map" do
      assert {:ok, %Model.ForumTopicClosed{}} = Cast.cast(%{}, Model.ForumTopicClosed)
    end
  end

  # ---------------------------------------------------------------------------
  # Models with nested model references
  # ---------------------------------------------------------------------------

  describe "model with nested model reference: MessageEntity" do
    test "casts entity with a nested User" do
      input = %{
        type: "text_mention",
        offset: 0,
        length: 5,
        user: %{id: 42, is_bot: false, first_name: "Alice"}
      }

      assert {:ok, %Model.MessageEntity{type: "text_mention", offset: 0, length: 5, user: user}} =
               Cast.cast(input, Model.MessageEntity)

      assert %Model.User{id: 42, first_name: "Alice"} = user
    end

    test "casts entity without optional user" do
      input = %{type: "bold", offset: 0, length: 4}

      assert {:ok, %Model.MessageEntity{type: "bold", user: nil}} =
               Cast.cast(input, Model.MessageEntity)
    end
  end

  describe "model with mixed nested references: PollAnswer" do
    test "casts with user and array of integers" do
      input = %{
        poll_id: "poll_abc",
        user: %{id: 7, is_bot: false, first_name: "Bob"},
        option_ids: [0, 2]
      }

      assert {:ok, %Model.PollAnswer{poll_id: "poll_abc", option_ids: [0, 2], user: user}} =
               Cast.cast(input, Model.PollAnswer)

      assert %Model.User{id: 7, first_name: "Bob"} = user
    end

    test "casts with voter_chat instead of user" do
      input = %{
        poll_id: "poll_xyz",
        voter_chat: %{id: 100, type: "group"},
        option_ids: [1]
      }

      assert {:ok, %Model.PollAnswer{voter_chat: chat, option_ids: [1]}} =
               Cast.cast(input, Model.PollAnswer)

      assert %Model.Chat{id: 100, type: "group"} = chat
    end
  end

  describe "Message with nested Chat and User" do
    test "casts message_id and nested chat" do
      input = %{
        message_id: 99,
        date: 1_700_000_000,
        chat: %{id: 12_345, type: "private"}
      }

      assert {:ok, %Model.Message{message_id: 99, date: 1_700_000_000, chat: chat}} =
               Cast.cast(input, Model.Message)

      assert %Model.Chat{id: 12_345, type: "private"} = chat
    end

    test "casts message with text and entities array" do
      input = %{
        message_id: 1,
        date: 1_700_000_001,
        chat: %{id: 1, type: "private"},
        text: "Hello world",
        entities: [
          %{type: "bold", offset: 0, length: 5},
          %{type: "italic", offset: 6, length: 5}
        ]
      }

      assert {:ok, %Model.Message{text: "Hello world", entities: [e1, e2]}} =
               Cast.cast(input, Model.Message)

      assert %Model.MessageEntity{type: "bold", offset: 0, length: 5} = e1
      assert %Model.MessageEntity{type: "italic", offset: 6, length: 5} = e2
    end
  end

  # ---------------------------------------------------------------------------
  # Union types (multi-type fields) - the fixed behavior
  # ---------------------------------------------------------------------------

  describe "union type [:integer, :string] - chat_id fields" do
    test "casts integer chat_id in ReplyParameters" do
      assert {:ok, %Model.ReplyParameters{message_id: 1, chat_id: 12_345}} =
               Cast.cast(%{message_id: 1, chat_id: 12_345}, Model.ReplyParameters)
    end

    test "casts string chat_id (channel username) in ReplyParameters" do
      assert {:ok, %Model.ReplyParameters{message_id: 1, chat_id: "@mychannel"}} =
               Cast.cast(%{message_id: 1, chat_id: "@mychannel"}, Model.ReplyParameters)
    end

    test "casts integer chat_id in BotCommandScopeChat" do
      assert {:ok, %Model.BotCommandScopeChat{type: "chat", chat_id: 99}} =
               Cast.cast(%{type: "chat", chat_id: 99}, Model.BotCommandScopeChat)
    end

    test "casts string chat_id in BotCommandScopeChat" do
      assert {:ok, %Model.BotCommandScopeChat{type: "chat", chat_id: "@channel"}} =
               Cast.cast(%{type: "chat", chat_id: "@channel"}, Model.BotCommandScopeChat)
    end
  end

  describe "union type [:string, :file] - media fields" do
    test "casts string file_id in InputMediaPhoto" do
      assert {:ok, %Model.InputMediaPhoto{type: "photo", media: "file_id_abc123"}} =
               Cast.cast(%{type: "photo", media: "file_id_abc123"}, Model.InputMediaPhoto)
    end

    test "casts {:file, path} tuple in InputMediaPhoto" do
      assert {:ok, %Model.InputMediaPhoto{media: {:file, "/tmp/photo.jpg"}}} =
               Cast.cast(%{type: "photo", media: {:file, "/tmp/photo.jpg"}}, Model.InputMediaPhoto)
    end

    test "casts {:file_content, content, name} in InputMediaPhoto" do
      assert {:ok, %Model.InputMediaPhoto{media: {:file_content, "data", "img.jpg"}}} =
               Cast.cast(
                 %{type: "photo", media: {:file_content, "data", "img.jpg"}},
                 Model.InputMediaPhoto
               )
    end

    test "casts string sticker in InputSticker" do
      input = %{sticker: "sticker_file_id", format: "static", emoji_list: ["😀"]}

      assert {:ok, %Model.InputSticker{sticker: "sticker_file_id", format: "static"}} =
               Cast.cast(input, Model.InputSticker)
    end

    test "casts file tuple sticker in InputSticker" do
      input = %{sticker: {:file, "/tmp/sticker.webp"}, format: "static", emoji_list: ["😀"]}

      assert {:ok, %Model.InputSticker{sticker: {:file, "/tmp/sticker.webp"}}} =
               Cast.cast(input, Model.InputSticker)
    end

    test "rejects invalid type for union field" do
      assert {:error, _} =
               Cast.cast(%{type: "photo", media: 12_345}, Model.InputMediaPhoto)
    end
  end

  # ---------------------------------------------------------------------------
  # Subtype (polymorphic) types
  # ---------------------------------------------------------------------------

  describe "subtype: ReactionType" do
    test "resolves to ReactionTypeEmoji" do
      assert {:ok, %Model.ReactionTypeEmoji{type: "emoji", emoji: "👍"}} =
               Cast.cast(%{type: "emoji", emoji: "👍"}, Model.ReactionType)
    end

    test "resolves to ReactionTypeCustomEmoji" do
      assert {:ok, %Model.ReactionTypeCustomEmoji{type: "custom_emoji", custom_emoji_id: "id123"}} =
               Cast.cast(%{type: "custom_emoji", custom_emoji_id: "id123"}, Model.ReactionType)
    end

    test "resolves to ReactionTypePaid" do
      assert {:ok, %Model.ReactionTypePaid{type: "paid"}} =
               Cast.cast(%{type: "paid"}, Model.ReactionType)
    end
  end

  describe "subtype: MessageOrigin" do
    test "resolves to MessageOriginUser" do
      input = %{type: "user", date: 1_700_000_000, sender_user: %{id: 1, is_bot: false, first_name: "Alice"}}

      assert {:ok, %Model.MessageOriginUser{type: "user", date: 1_700_000_000, sender_user: user}} =
               Cast.cast(input, Model.MessageOrigin)

      assert %Model.User{id: 1, first_name: "Alice"} = user
    end

    test "resolves to MessageOriginHiddenUser" do
      input = %{type: "hidden_user", date: 1_700_000_001, sender_user_name: "Anonymous"}

      assert {:ok, %Model.MessageOriginHiddenUser{sender_user_name: "Anonymous"}} =
               Cast.cast(input, Model.MessageOrigin)
    end

    test "resolves to MessageOriginChannel" do
      input = %{
        type: "channel",
        date: 1_700_000_002,
        chat: %{id: 42, type: "channel"},
        message_id: 55
      }

      assert {:ok, %Model.MessageOriginChannel{message_id: 55, chat: chat}} =
               Cast.cast(input, Model.MessageOrigin)

      assert %Model.Chat{id: 42} = chat
    end
  end

  describe "subtype: ChatMember" do
    test "resolves to ChatMemberOwner" do
      input = %{
        status: "creator",
        user: %{id: 1, is_bot: false, first_name: "Alice"},
        is_anonymous: false
      }

      assert {:ok, %Model.ChatMemberOwner{status: "creator", is_anonymous: false, user: user}} =
               Cast.cast(input, Model.ChatMember)

      assert %Model.User{id: 1, first_name: "Alice"} = user
    end

    test "resolves to ChatMemberMember" do
      input = %{status: "member", user: %{id: 2, is_bot: false, first_name: "Bob"}}

      assert {:ok, %Model.ChatMemberMember{status: "member"}} =
               Cast.cast(input, Model.ChatMember)
    end

    test "resolves to ChatMemberBanned" do
      input = %{
        status: "kicked",
        user: %{id: 3, is_bot: false, first_name: "Eve"},
        until_date: 0
      }

      assert {:ok, %Model.ChatMemberBanned{status: "kicked"}} =
               Cast.cast(input, Model.ChatMember)
    end
  end

  # ---------------------------------------------------------------------------
  # Already-cast struct passthrough
  # ---------------------------------------------------------------------------

  describe "already-cast struct passthrough" do
    test "returns existing struct unchanged" do
      existing = %Model.MessageId{message_id: 77}
      assert {:ok, ^existing} = Cast.cast(existing, Model.MessageId)
    end

    test "returns existing User struct unchanged" do
      existing = %Model.User{id: 1, is_bot: false, first_name: "Alice"}
      assert {:ok, ^existing} = Cast.cast(existing, Model.User)
    end
  end

  # ---------------------------------------------------------------------------
  # Keyword list input
  # ---------------------------------------------------------------------------

  describe "keyword list input" do
    test "casts a keyword list to a struct" do
      assert {:ok, %Model.MessageId{message_id: 5}} =
               Cast.cast([message_id: 5], Model.MessageId)
    end
  end

  # ---------------------------------------------------------------------------
  # Error cases
  # ---------------------------------------------------------------------------

  describe "error cases" do
    test "non-map input for model type" do
      assert {:error, %ExGram.Error{message: "Expected a map for type " <> _}} =
               Cast.cast(true, Model.Message)
    end

    test "non-map input for model type with integer" do
      assert {:error, %ExGram.Error{}} = Cast.cast(42, Model.MessageId)
    end

    test "wrong type for nested field propagates error" do
      input = %{message_id: "not_an_int", date: 0, chat: %{id: 1, type: "private"}}

      assert {:error, %ExGram.Error{message: "Expected integer, got: \"not_an_int\""}} =
               Cast.cast(input, Model.Message)
    end

    test "wrong type in array element propagates error" do
      assert {:error, %ExGram.Error{message: "Expected integer, got: \"x\""}} =
               Cast.cast(["x", "y"], {:array, :integer})
    end

    test "cast! raises on error" do
      assert_raise ExGram.Error, fn ->
        Cast.cast!(true, Model.Message)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Complex end-to-end
  # ---------------------------------------------------------------------------

  describe "complex end-to-end" do
    test "full Update with nested Message, Chat, User, and entities" do
      input = %{
        update_id: 1234,
        message: %{
          message_id: 10,
          date: 1_700_000_000,
          chat: %{id: 5, type: "private"},
          from: %{id: 99, is_bot: false, first_name: "Carol"},
          text: "Hello",
          entities: [%{type: "bold", offset: 0, length: 5}]
        }
      }

      assert {:ok, %Model.Update{update_id: 1234, message: msg}} =
               Cast.cast(input, Model.Update)

      assert %Model.Message{message_id: 10, text: "Hello"} = msg
      assert %Model.Chat{id: 5, type: "private"} = msg.chat
      assert %Model.User{id: 99, first_name: "Carol"} = msg.from
      assert [%Model.MessageEntity{type: "bold"}] = msg.entities
    end

    test "InlineKeyboardMarkup with multiple rows and mixed buttons" do
      input = %{
        inline_keyboard: [
          [
            %{text: "Yes", callback_data: "yes"},
            %{text: "No", callback_data: "no"}
          ],
          [
            %{text: "Visit", url: "https://example.com"}
          ]
        ]
      }

      assert {:ok, %Model.InlineKeyboardMarkup{inline_keyboard: [[yes, no], [visit]]}} =
               Cast.cast(input, Model.InlineKeyboardMarkup)

      assert %Model.InlineKeyboardButton{text: "Yes", callback_data: "yes"} = yes
      assert %Model.InlineKeyboardButton{text: "No", callback_data: "no"} = no
      assert %Model.InlineKeyboardButton{text: "Visit", url: "https://example.com"} = visit
    end

    test "ReactionType inside a message reaction context" do
      reactions = [
        %{type: "emoji", emoji: "🔥"},
        %{type: "custom_emoji", custom_emoji_id: "my_custom_id"},
        %{type: "paid"}
      ]

      assert {:ok, casted} = Cast.cast(reactions, {:array, Model.ReactionType})

      assert [
               %Model.ReactionTypeEmoji{emoji: "🔥"},
               %Model.ReactionTypeCustomEmoji{custom_emoji_id: "my_custom_id"},
               %Model.ReactionTypePaid{}
             ] = casted
    end
  end
end
