defmodule ExGramTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.BotCommand
  alias ExGram.Model.Chat
  alias ExGram.Model.InputPollOption
  alias ExGram.Model.Location
  alias ExGram.Model.Message
  alias ExGram.Model.PhotoSize
  alias ExGram.Model.Sticker
  alias ExGram.Model.User

  doctest ExGram

  setup {ExGram.Test, :verify_on_exit!}

  # --- Basic Methods ---

  describe "get_me/0" do
    test "returns User struct with correct fields" do
      ExGram.Test.expect(:get_me, %{
        id: 123_456_789,
        is_bot: true,
        first_name: "TestBot",
        username: "test_bot",
        can_join_groups: true,
        can_read_all_group_messages: false,
        supports_inline_queries: true
      })

      {:ok, user} = ExGram.get_me()

      assert %User{} = user
      assert user.id == 123_456_789
      assert user.is_bot == true
      assert user.first_name == "TestBot"
      assert user.username == "test_bot"
      assert user.can_join_groups == true
      assert user.supports_inline_queries == true
    end
  end

  describe "get_updates/0" do
    test "returns array of Update structs with nested Message and User" do
      ExGram.Test.expect(:get_updates, [
        %{
          update_id: 1,
          message: %{
            message_id: 100,
            date: 1_700_000_000,
            chat: %{id: 123, type: "private"},
            from: %{id: 456, is_bot: false, first_name: "Test"},
            text: "Hello"
          }
        }
      ])

      {:ok, updates} = ExGram.get_updates()

      assert is_list(updates)
      assert [update] = updates
      assert %ExGram.Model.Update{} = update
      assert update.update_id == 1
      assert %Message{} = update.message
      assert %User{} = update.message.from
      assert %Chat{} = update.message.chat
    end
  end

  describe "log_out/0" do
    test "returns true on success" do
      ExGram.Test.expect(:log_out, true)

      {:ok, result} = ExGram.log_out()

      assert result == true
    end
  end

  describe "close/0" do
    test "returns true on success" do
      ExGram.Test.expect(:close, true)

      {:ok, result} = ExGram.close()

      assert result == true
    end
  end

  # --- Webhook Methods ---

  describe "set_webhook/1" do
    test "sets webhook with url and returns true" do
      ExGram.Test.expect(:set_webhook, true)

      {:ok, result} = ExGram.set_webhook("https://example.com/webhook")

      assert result == true
    end
  end

  describe "delete_webhook/0" do
    test "deletes webhook and returns true" do
      ExGram.Test.expect(:delete_webhook, true)

      {:ok, result} = ExGram.delete_webhook()

      assert result == true
    end
  end

  describe "get_webhook_info/0" do
    test "returns WebhookInfo struct" do
      ExGram.Test.expect(:get_webhook_info, %{
        url: "https://example.com/webhook",
        has_custom_certificate: false,
        pending_update_count: 0
      })

      {:ok, info} = ExGram.get_webhook_info()

      assert %ExGram.Model.WebhookInfo{} = info
      assert info.url == "https://example.com/webhook"
      assert info.has_custom_certificate == false
    end
  end

  # --- Message Sending Methods ---

  describe "send_message/2" do
    test "returns Message struct with nested User and Chat" do
      ExGram.Test.expect(:send_message, %{
        message_id: 100,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private", first_name: "Test"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        text: "Hello!"
      })

      {:ok, message} = ExGram.send_message(123, "Hello!")

      assert %Message{} = message
      assert message.message_id == 100
      assert %Chat{} = message.chat
      assert message.chat.id == 123
      assert %User{} = message.from
      assert message.from.id == 999
      assert message.text == "Hello!"
    end

    test "sends message with optional parameters" do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:chat_id] == 123
        assert body[:text] == "Test"
        assert body[:parse_mode] == "HTML"

        {:ok,
         %{
           message_id: 101,
           date: 1_700_000_000,
           chat: %{id: 123, type: "private"},
           from: %{id: 999, is_bot: true, first_name: "Bot"},
           text: "Test"
         }}
      end)

      {:ok, _message} = ExGram.send_message(123, "Test", parse_mode: "HTML")
    end
  end

  describe "forward_message/3" do
    test "forwards message and returns Message struct" do
      ExGram.Test.expect(:forward_message, %{
        message_id: 102,
        date: 1_700_000_000,
        chat: %{id: 456, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        forward_origin: %{
          type: "user",
          date: 1_699_999_900,
          sender_user: %{id: 123, is_bot: false, first_name: "Original"}
        },
        text: "Forwarded"
      })

      {:ok, message} = ExGram.forward_message(456, 123, 100)

      assert %Message{} = message
      assert message.message_id == 102
      # MessageOrigin is polymorphic - can be MessageOriginUser, MessageOriginHiddenUser, etc.
      assert message.forward_origin.type == "user"
      assert %User{} = message.forward_origin.sender_user
    end
  end

  describe "copy_message/3" do
    test "copies message and returns MessageId struct" do
      ExGram.Test.expect(:copy_message, %{
        message_id: 103
      })

      {:ok, message_id} = ExGram.copy_message(456, 123, 100)

      assert %ExGram.Model.MessageId{} = message_id
      assert message_id.message_id == 103
    end
  end

  describe "send_photo/2" do
    test "sends photo with file_id string" do
      ExGram.Test.expect(:send_photo, %{
        message_id: 104,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        photo: [
          %{
            file_id: "photo123",
            file_unique_id: "unique123",
            width: 640,
            height: 480
          }
        ]
      })

      {:ok, message} = ExGram.send_photo(123, "photo123")

      assert %Message{} = message
      assert is_list(message.photo)
      [photo | _] = message.photo
      assert %PhotoSize{} = photo
      assert photo.file_id == "photo123"
    end

    test "sends photo with {:file, path}" do
      ExGram.Test.expect(:send_photo, fn _body ->
        # When using file upload, body is {:multipart, [...]}
        # We can't easily assert on the structure, so just return success
        {:ok,
         %{
           message_id: 105,
           date: 1_700_000_000,
           chat: %{id: 123, type: "private"},
           from: %{id: 999, is_bot: true, first_name: "Bot"},
           photo: [%{file_id: "photo456", file_unique_id: "unique456", width: 800, height: 600}]
         }}
      end)

      {:ok, message} = ExGram.send_photo(123, {:file, "/tmp/test.jpg"})

      assert %Message{} = message
      assert message.message_id == 105
    end
  end

  describe "send_audio/2" do
    test "sends audio with {:file_content, contents, filename}" do
      ExGram.Test.expect(:send_audio, fn _body ->
        # When using file upload, body is {:multipart, [...]}
        # We can't easily assert on the structure, so just return success
        {:ok,
         %{
           message_id: 106,
           date: 1_700_000_000,
           chat: %{id: 123, type: "private"},
           from: %{id: 999, is_bot: true, first_name: "Bot"},
           audio: %{
             file_id: "audio123",
             file_unique_id: "unique_audio",
             duration: 180
           }
         }}
      end)

      {:ok, message} = ExGram.send_audio(123, {:file_content, <<1, 2, 3>>, "test.mp3"})

      assert %Message{} = message
      assert %ExGram.Model.Audio{} = message.audio
      assert message.audio.duration == 180
    end
  end

  describe "send_document/2" do
    test "sends document with file_id string" do
      ExGram.Test.expect(:send_document, %{
        message_id: 107,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        document: %{
          file_id: "doc123",
          file_unique_id: "unique_doc",
          file_name: "test.pdf"
        }
      })

      {:ok, message} = ExGram.send_document(123, "doc123")

      assert %Message{} = message
      assert %ExGram.Model.Document{} = message.document
    end
  end

  describe "send_video/2" do
    test "sends video with file_id string" do
      ExGram.Test.expect(:send_video, %{
        message_id: 108,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        video: %{
          file_id: "video123",
          file_unique_id: "unique_video",
          width: 1920,
          height: 1080,
          duration: 60
        }
      })

      {:ok, message} = ExGram.send_video(123, "video123")

      assert %Message{} = message
      assert %ExGram.Model.Video{} = message.video
      assert message.video.width == 1920
    end
  end

  describe "send_location/3" do
    test "sends location and returns Message with Location struct" do
      ExGram.Test.expect(:send_location, %{
        message_id: 109,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        location: %{
          latitude: 40.7128,
          longitude: -74.0060
        }
      })

      {:ok, message} = ExGram.send_location(123, 40.7128, -74.0060)

      assert %Message{} = message
      assert %Location{} = message.location
      assert message.location.latitude == 40.7128
      assert message.location.longitude == -74.0060
    end
  end

  describe "send_venue/5" do
    test "sends venue with location info" do
      ExGram.Test.expect(:send_venue, %{
        message_id: 110,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        venue: %{
          location: %{latitude: 40.7128, longitude: -74.0060},
          title: "Test Venue",
          address: "123 Test St"
        }
      })

      {:ok, message} = ExGram.send_venue(123, 40.7128, -74.0060, "Test Venue", "123 Test St")

      assert %Message{} = message
      assert %ExGram.Model.Venue{} = message.venue
      assert %Location{} = message.venue.location
      assert message.venue.title == "Test Venue"
    end
  end

  describe "send_contact/3" do
    test "sends contact information" do
      ExGram.Test.expect(:send_contact, %{
        message_id: 111,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        contact: %{
          phone_number: "+1234567890",
          first_name: "John"
        }
      })

      {:ok, message} = ExGram.send_contact(123, "+1234567890", "John")

      assert %Message{} = message
      assert %ExGram.Model.Contact{} = message.contact
      assert message.contact.phone_number == "+1234567890"
    end
  end

  describe "send_poll/3" do
    test "sends poll and returns Message with Poll struct" do
      ExGram.Test.expect(:send_poll, %{
        message_id: 112,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        poll: %{
          id: "poll123",
          question: "What is your favorite color?",
          options: [
            %{text: "Red", voter_count: 0},
            %{text: "Blue", voter_count: 0}
          ],
          is_closed: false,
          is_anonymous: true
        }
      })

      # send_poll expects InputPollOption structs
      options = [
        %InputPollOption{text: "Red"},
        %InputPollOption{text: "Blue"}
      ]

      {:ok, message} = ExGram.send_poll(123, "What is your favorite color?", options)

      assert %Message{} = message
      assert %ExGram.Model.Poll{} = message.poll
      assert is_list(message.poll.options)
      assert length(message.poll.options) == 2
    end
  end

  describe "send_dice/1" do
    test "sends dice and returns Message with Dice struct" do
      ExGram.Test.expect(:send_dice, %{
        message_id: 113,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        dice: %{
          emoji: "🎲",
          value: 4
        }
      })

      {:ok, message} = ExGram.send_dice(123)

      assert %Message{} = message
      assert %ExGram.Model.Dice{} = message.dice
      assert message.dice.emoji == "🎲"
      assert message.dice.value == 4
    end
  end

  describe "send_chat_action/2" do
    test "sends chat action and returns true" do
      ExGram.Test.expect(:send_chat_action, true)

      {:ok, result} = ExGram.send_chat_action(123, "typing")

      assert result == true
    end
  end

  # --- Message Editing Methods ---

  describe "edit_message_text/2" do
    test "edits message text and returns Message struct" do
      ExGram.Test.expect(:edit_message_text, %{
        message_id: 100,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        text: "Edited text",
        edit_date: 1_700_000_100
      })

      {:ok, message} = ExGram.edit_message_text("Edited text", chat_id: 123, message_id: 100)

      assert %Message{} = message
      assert message.text == "Edited text"
      assert message.edit_date == 1_700_000_100
    end
  end

  describe "delete_message/2" do
    test "deletes message and returns true" do
      ExGram.Test.expect(:delete_message, true)

      {:ok, result} = ExGram.delete_message(123, 100)

      assert result == true
    end
  end

  describe "delete_messages/2" do
    test "bulk deletes messages and returns true" do
      ExGram.Test.expect(:delete_messages, true)

      {:ok, result} = ExGram.delete_messages(123, [100, 101, 102])

      assert result == true
    end
  end

  # --- Chat Management Methods ---

  describe "get_chat/1" do
    test "returns ChatFullInfo struct with nested fields" do
      ExGram.Test.expect(:get_chat, %{
        id: 123,
        type: "private",
        username: "testuser",
        first_name: "Test",
        photo: %{
          small_file_id: "small123",
          small_file_unique_id: "small_unique",
          big_file_id: "big123",
          big_file_unique_id: "big_unique"
        }
      })

      {:ok, chat} = ExGram.get_chat(123)

      assert %ExGram.Model.ChatFullInfo{} = chat
      assert chat.id == 123
      assert chat.type == "private"
      assert %ExGram.Model.ChatPhoto{} = chat.photo
    end
  end

  describe "get_chat_member/2" do
    test "returns ChatMember struct" do
      ExGram.Test.expect(:get_chat_member, %{
        status: "member",
        user: %{id: 456, is_bot: false, first_name: "User"}
      })

      {:ok, member} = ExGram.get_chat_member(123, 456)

      # ChatMember is polymorphic - can be ChatMemberMember, ChatMemberAdministrator, etc.
      assert member.status == "member"
      assert %User{} = member.user
    end
  end

  describe "get_chat_member_count/1" do
    test "returns integer count" do
      ExGram.Test.expect(:get_chat_member_count, 42)

      {:ok, count} = ExGram.get_chat_member_count(123)

      assert is_integer(count)
      assert count == 42
    end
  end

  describe "get_chat_administrators/1" do
    test "returns array of ChatMember structs" do
      ExGram.Test.expect(:get_chat_administrators, [
        %{status: "administrator", user: %{id: 100, is_bot: false, first_name: "Admin1"}},
        %{status: "creator", user: %{id: 101, is_bot: false, first_name: "Creator"}}
      ])

      {:ok, admins} = ExGram.get_chat_administrators(123)

      assert is_list(admins)
      assert length(admins) == 2
      # ChatMember is polymorphic, so we just check the common fields
      assert Enum.all?(admins, fn admin -> admin.status in ["administrator", "creator"] end)
      assert Enum.all?(admins, fn admin -> match?(%User{}, admin.user) end)
    end
  end

  describe "leave_chat/1" do
    test "leaves chat and returns true" do
      ExGram.Test.expect(:leave_chat, true)

      {:ok, result} = ExGram.leave_chat(123)

      assert result == true
    end
  end

  describe "ban_chat_member/2" do
    test "bans chat member and returns true" do
      ExGram.Test.expect(:ban_chat_member, true)

      {:ok, result} = ExGram.ban_chat_member(123, 456)

      assert result == true
    end
  end

  describe "unban_chat_member/2" do
    test "unbans chat member and returns true" do
      ExGram.Test.expect(:unban_chat_member, true)

      {:ok, result} = ExGram.unban_chat_member(123, 456)

      assert result == true
    end
  end

  describe "pin_chat_message/2" do
    test "pins message and returns true" do
      ExGram.Test.expect(:pin_chat_message, true)

      {:ok, result} = ExGram.pin_chat_message(123, 100)

      assert result == true
    end
  end

  # --- Callback Query Methods ---

  describe "answer_callback_query/1" do
    test "answers callback query with text and returns true" do
      ExGram.Test.expect(:answer_callback_query, true)

      {:ok, result} = ExGram.answer_callback_query("cbq123", text: "Processing...")

      assert result == true
    end
  end

  # --- Inline Query Methods ---

  describe "answer_inline_query/2" do
    test "answers inline query with results array and returns true" do
      ExGram.Test.expect(:answer_inline_query, true)

      # answer_inline_query expects InlineQueryResult structs
      results = [
        %ExGram.Model.InlineQueryResultArticle{
          type: "article",
          id: "1",
          title: "Result 1",
          input_message_content: %ExGram.Model.InputTextMessageContent{
            message_text: "Text 1"
          }
        }
      ]

      {:ok, result} = ExGram.answer_inline_query("iq123", results)

      assert result == true
    end
  end

  # --- Bot Profile Methods ---

  describe "set_my_commands/1" do
    test "sets bot commands and returns true" do
      ExGram.Test.expect(:set_my_commands, true)

      # set_my_commands expects BotCommand structs
      commands = [
        %BotCommand{command: "start", description: "Start the bot"},
        %BotCommand{command: "help", description: "Show help"}
      ]

      {:ok, result} = ExGram.set_my_commands(commands)

      assert result == true
    end
  end

  describe "get_my_commands/0" do
    test "returns array of BotCommand structs" do
      ExGram.Test.expect(:get_my_commands, [
        %{command: "start", description: "Start the bot"},
        %{command: "help", description: "Show help"}
      ])

      {:ok, commands} = ExGram.get_my_commands()

      assert is_list(commands)
      assert Enum.all?(commands, &match?(%BotCommand{}, &1))
    end
  end

  describe "delete_my_commands/0" do
    test "deletes bot commands and returns true" do
      ExGram.Test.expect(:delete_my_commands, true)

      {:ok, result} = ExGram.delete_my_commands()

      assert result == true
    end
  end

  describe "set_my_name/1" do
    test "sets bot name and returns true" do
      ExGram.Test.expect(:set_my_name, true)

      {:ok, result} = ExGram.set_my_name(name: "TestBot")

      assert result == true
    end
  end

  describe "get_my_name/0" do
    test "returns BotName struct" do
      ExGram.Test.expect(:get_my_name, %{name: "TestBot"})

      {:ok, bot_name} = ExGram.get_my_name()

      assert %ExGram.Model.BotName{} = bot_name
      assert bot_name.name == "TestBot"
    end
  end

  describe "set_my_description/1" do
    test "sets bot description and returns true" do
      ExGram.Test.expect(:set_my_description, true)

      {:ok, result} = ExGram.set_my_description(description: "A test bot")

      assert result == true
    end
  end

  describe "get_my_description/0" do
    test "returns BotDescription struct" do
      ExGram.Test.expect(:get_my_description, %{description: "A test bot"})

      {:ok, desc} = ExGram.get_my_description()

      assert %ExGram.Model.BotDescription{} = desc
      assert desc.description == "A test bot"
    end
  end

  # --- File Methods ---

  describe "get_file/1" do
    test "returns File struct with file_path" do
      ExGram.Test.expect(:get_file, %{
        file_id: "file123",
        file_unique_id: "unique_file",
        file_size: 1024,
        file_path: "photos/file.jpg"
      })

      {:ok, file} = ExGram.get_file("file123")

      assert %ExGram.Model.File{} = file
      assert file.file_id == "file123"
      assert file.file_path == "photos/file.jpg"
    end
  end

  describe "get_user_profile_photos/1" do
    test "returns UserProfilePhotos with nested PhotoSize arrays" do
      ExGram.Test.expect(:get_user_profile_photos, %{
        total_count: 2,
        photos: [
          [
            %{file_id: "photo1", file_unique_id: "unique1", width: 160, height: 160},
            %{file_id: "photo2", file_unique_id: "unique2", width: 640, height: 640}
          ]
        ]
      })

      {:ok, photos} = ExGram.get_user_profile_photos(123)

      assert %ExGram.Model.UserProfilePhotos{} = photos
      assert photos.total_count == 2
      assert is_list(photos.photos)
      assert [[photo | _] | _] = photos.photos
      assert %PhotoSize{} = photo
    end
  end

  # --- Sticker Methods ---

  describe "send_sticker/2" do
    test "sends sticker and returns Message with Sticker" do
      ExGram.Test.expect(:send_sticker, %{
        message_id: 114,
        date: 1_700_000_000,
        chat: %{id: 123, type: "private"},
        from: %{id: 999, is_bot: true, first_name: "Bot"},
        sticker: %{
          file_id: "sticker123",
          file_unique_id: "unique_sticker",
          type: "regular",
          width: 512,
          height: 512,
          is_animated: false,
          is_video: false
        }
      })

      {:ok, message} = ExGram.send_sticker(123, "sticker123")

      assert %Message{} = message
      assert %Sticker{} = message.sticker
    end
  end

  describe "get_sticker_set/1" do
    test "returns StickerSet with nested Sticker array" do
      ExGram.Test.expect(:get_sticker_set, %{
        name: "test_sticker_set",
        title: "Test Stickers",
        sticker_type: "regular",
        stickers: [
          %{
            file_id: "sticker1",
            file_unique_id: "unique1",
            type: "regular",
            width: 512,
            height: 512,
            is_animated: false,
            is_video: false
          }
        ]
      })

      {:ok, sticker_set} = ExGram.get_sticker_set("test_sticker_set")

      assert %ExGram.Model.StickerSet{} = sticker_set
      assert sticker_set.name == "test_sticker_set"
      assert is_list(sticker_set.stickers)
      assert [sticker | _] = sticker_set.stickers
      assert %Sticker{} = sticker
    end
  end

  # --- Error Handling ---

  describe "error handling" do
    test "handles 400 Bad Request errors" do
      ExGram.Test.expect(
        :send_message,
        {:error,
         %ExGram.Error{
           code: 400,
           message: "Bad Request: chat not found"
         }}
      )

      result = ExGram.send_message(999, "Hello")

      assert {:error, %ExGram.Error{code: 400, message: "Bad Request: chat not found"}} = result
    end

    test "handles 403 Forbidden errors" do
      ExGram.Test.expect(
        :send_message,
        {:error,
         %ExGram.Error{
           code: 403,
           message: "Forbidden: bot was blocked by the user"
         }}
      )

      result = ExGram.send_message(123, "Hello")

      assert {:error, %ExGram.Error{code: 403}} = result
    end

    test "handles 429 Too Many Requests errors" do
      ExGram.Test.expect(
        :get_me,
        {:error,
         %ExGram.Error{
           code: 429,
           message: "Too Many Requests: retry after 30"
         }}
      )

      result = ExGram.get_me()

      assert {:error, %ExGram.Error{code: 429}} = result
    end
  end
end
