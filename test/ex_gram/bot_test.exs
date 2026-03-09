defmodule ExGram.BotTest do
  use ExUnit.Case, async: true

  import ExGram.TestHelpers

  setup {ExGram.Test, :verify_on_exit!}

  # --- Command Handling ---

  describe "command handling" do
    defmodule CommandBot do
      @moduledoc false
      use ExGram.Bot, name: :command_test_bot

      command("start")
      command("help")
      command("echo")

      def handle({:command, :start, _}, context) do
        answer(context, "Welcome!")
      end

      def handle({:command, :help, _}, context) do
        answer(context, "Help message")
      end

      def handle({:command, :echo, %{text: text}}, context) do
        # Extract text after the command - text will be "/echo hello world"
        args = text |> String.replace_prefix("/echo", "") |> String.trim()
        answer(context, "Echo: #{args}")
      end

      def handle({:command, cmd, _}, context) when is_binary(cmd) do
        answer(context, "Unknown command: #{cmd}")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = CommandBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "responds to /start command", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:chat_id] == 123
        assert body[:text] == "Welcome!"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Welcome!"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "/start"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "responds to /help command", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Help message"

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Help message"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "/help"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "responds to /echo command with message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Echo: hello world"

        {:ok,
         %{
           message_id: 3,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Echo: hello world"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "/echo hello world"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles unknown command", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Unknown command: unknown"

        {:ok,
         %{
           message_id: 4,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Unknown command: unknown"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "/unknown"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Text Message Handling ---

  describe "text message handling" do
    defmodule TextBot do
      @moduledoc false
      use ExGram.Bot, name: :text_test_bot

      def handle({:text, text, _msg}, context) do
        answer(context, "You said: #{text}")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = TextBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "responds to plain text message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "You said: hello"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "You said: hello"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "hello"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles empty text", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "You said: "

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "You said: "
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: ""
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Callback Query Handling ---

  describe "callback query handling" do
    defmodule CallbackBot do
      @moduledoc false
      use ExGram.Bot, name: :callback_test_bot

      def handle({:callback_query, %{data: "action:" <> action} = query}, context) do
        context
        |> answer_callback(query, text: "Processing #{action}")
        |> answer("Action: #{action}")
      end

      def handle({:callback_query, %{data: data} = query}, context) do
        answer_callback(context, query, text: "Unknown: #{data}")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = CallbackBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "handles button press with action pattern", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_callback_query, fn body ->
        assert body[:callback_query_id] == "cbq_123"
        assert body[:text] == "Processing approve"

        {:ok, true}
      end)

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Action: approve"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Action: approve"
         }}
      end)

      update =
        build_update(%{
          callback_query:
            build_callback_query(%{
              id: "cbq_123",
              from: build_user(%{id: 123}),
              message: build_message(%{chat: build_chat(%{id: 123})}),
              data: "action:approve"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles button press with action reject", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_callback_query, fn body ->
        assert body[:text] == "Processing reject"

        {:ok, true}
      end)

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Action: reject"

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Action: reject"
         }}
      end)

      update =
        build_update(%{
          callback_query:
            build_callback_query(%{
              id: "cbq_456",
              from: build_user(%{id: 123}),
              message: build_message(%{chat: build_chat(%{id: 123})}),
              data: "action:reject"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles generic callback data", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_callback_query, fn body ->
        assert body[:text] == "Unknown: other_data"

        {:ok, true}
      end)

      update =
        build_update(%{
          callback_query:
            build_callback_query(%{
              id: "cbq_789",
              from: build_user(%{id: 123}),
              message: build_message(%{chat: build_chat(%{id: 123})}),
              data: "other_data"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Inline Query Handling ---

  describe "inline query handling" do
    defmodule InlineBot do
      @moduledoc false
      use ExGram.Bot, name: :inline_test_bot

      def handle({:inline_query, query}, context) do
        results = [
          %ExGram.Model.InlineQueryResultArticle{
            type: "article",
            id: "1",
            title: query.query,
            input_message_content: %ExGram.Model.InputTextMessageContent{
              message_text: "You searched for: #{query.query}"
            }
          }
        ]

        answer_inline_query(context, results)
      end
    end

    setup context do
      # Stub get_me to prevent unexpected API call errors
      ExGram.Test.stub(:get_me, fn _ ->
        {:ok, build_user(%{id: 999, is_bot: true, first_name: "TestBot", username: "test_bot"})}
      end)

      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = InlineBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")

      {:ok, bot_name: bot_name}
    end

    test "handles inline query and returns results", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_inline_query, fn body ->
        assert body[:inline_query_id] == "iq_123"
        assert is_list(body[:results])
        [result | _] = body[:results]
        assert result[:title] == "search term"

        {:ok, true}
      end)

      update =
        build_update(%{
          inline_query:
            build_inline_query(%{
              id: "iq_123",
              from: build_user(%{id: 123}),
              query: "search term"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Location Handling ---

  describe "location handling" do
    defmodule LocationBot do
      @moduledoc false
      use ExGram.Bot, name: :location_test_bot

      def handle({:location, %{latitude: lat, longitude: lon}}, context) do
        answer(context, "Location: #{lat}, #{lon}")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = LocationBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "handles location message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Location: 40.7128, -74.006"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Location: 40.7128, -74.006"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              location: build_location(%{latitude: 40.7128, longitude: -74.0060})
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Edited Message Handling ---

  describe "edited message handling" do
    defmodule EditBot do
      @moduledoc false
      use ExGram.Bot, name: :edit_test_bot

      def handle({:edited_message, _msg}, context) do
        answer(context, "Message was edited")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = EditBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "handles edited message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Message was edited"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Message was edited"
         }}
      end)

      update =
        build_update(%{
          edited_message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "Edited text",
              edit_date: System.system_time(:second)
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Generic Message Handling ---

  describe "generic message handling" do
    defmodule GenericBot do
      @moduledoc false
      use ExGram.Bot, name: :generic_test_bot

      def handle({:message, msg}, context) do
        cond do
          msg.photo -> answer(context, "Photo received")
          msg.document -> answer(context, "Document received")
          msg.sticker -> answer(context, "Sticker received")
          true -> answer(context, "Unknown message type")
        end
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = GenericBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "handles photo message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Photo received"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Photo received"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              photo: [%{file_id: "photo123", file_unique_id: "unique", width: 640, height: 480}]
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles document message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Document received"

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Document received"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              document: %{file_id: "doc123", file_unique_id: "unique", file_name: "test.pdf"}
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "handles sticker message", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Sticker received"

        {:ok,
         %{
           message_id: 3,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Sticker received"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              sticker: %{
                file_id: "sticker123",
                file_unique_id: "unique",
                type: "regular",
                width: 512,
                height: 512,
                is_animated: false,
                is_video: false
              }
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Default/Catch-all Handler ---

  describe "default handler" do
    defmodule DefaultBot do
      @moduledoc false
      use ExGram.Bot, name: :default_test_bot

      def handle({:update, _update}, context) do
        # Log or ignore unhandled updates
        context
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = DefaultBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "handles unhandled update types without crashing", %{bot_name: bot_name} do
      # No expectations - the bot should just ignore the update
      update =
        build_update(%{
          poll: %{
            id: "poll123",
            question: %{text: "Question?"},
            options: [],
            is_closed: false,
            is_anonymous: true
          }
        })

      # This should not crash
      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- Regex Pattern Handling ---

  describe "regex pattern handling" do
    defmodule RegexBot do
      @moduledoc false
      use ExGram.Bot, name: :regex_test_bot

      regex(~r/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/, :email)
      regex(~r/https?:\/\/\S+/, :url)

      def handle({:regex, :email, _msg}, context) do
        answer(context, "Email detected!")
      end

      def handle({:regex, :url, _msg}, context) do
        answer(context, "URL detected!")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = RegexBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "matches email pattern", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Email detected!"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Email detected!"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "Contact me at test@example.com"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end

    test "matches URL pattern", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "URL detected!"

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "URL detected!"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "Check out https://example.com"
            })
        })

      ExGram.Test.push_update(bot_name, update)
    end
  end

  # --- DSL Method Chaining ---

  describe "DSL method chaining" do
    defmodule ChainingBot do
      @moduledoc false
      use ExGram.Bot, name: :chaining_test_bot

      command("multi")

      def handle({:callback_query, %{data: "complete"} = query}, context) do
        context
        |> answer_callback(query, text: "Processing...")
        |> answer("Step 1 complete")
      end

      def handle({:command, :multi, _}, context) do
        context
        |> answer("First message")
        |> answer("Second message")
        |> answer("Third message")
      end

      def handle(_, context), do: context
    end

    setup context do
      {bot_name, module_name} = unique_bot_name(context)
      {:ok, _pid} = ChainingBot.start_link(method: :test, name: module_name, bot_name: bot_name, token: "test_token")
      {:ok, bot_name: bot_name}
    end

    test "chaining answer_callback and answer executes both calls", %{bot_name: bot_name} do
      ExGram.Test.expect(:answer_callback_query, fn body ->
        assert body[:text] == "Processing..."

        {:ok, true}
      end)

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Step 1 complete"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Step 1 complete"
         }}
      end)

      update =
        build_update(%{
          callback_query:
            build_callback_query(%{
              id: "cbq_999",
              from: build_user(%{id: 123}),
              message: build_message(%{chat: build_chat(%{id: 123})}),
              data: "complete"
            })
        })

      ExGram.Test.push_update(bot_name, update)

      # Verify both calls were made
      calls = ExGram.Test.get_calls()
      assert length(calls) == 2
      assert Enum.any?(calls, fn {_, action, _} -> action == :answer_callback_query end)
      assert Enum.any?(calls, fn {_, action, _} -> action == :send_message end)
    end

    test "chaining multiple answer calls sends multiple messages", %{bot_name: bot_name} do
      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "First message"

        {:ok,
         %{
           message_id: 1,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "First message"
         }}
      end)

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Second message"

        {:ok,
         %{
           message_id: 2,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Second message"
         }}
      end)

      ExGram.Test.expect(:send_message, fn body ->
        assert body[:text] == "Third message"

        {:ok,
         %{
           message_id: 3,
           chat: %{id: 123, type: "private"},
           date: System.system_time(:second),
           text: "Third message"
         }}
      end)

      update =
        build_update(%{
          message:
            build_message(%{
              chat: build_chat(%{id: 123}),
              text: "/multi"
            })
        })

      ExGram.Test.push_update(bot_name, update)

      # Verify all three calls were made in order
      calls = ExGram.Test.get_calls()
      assert length(calls) == 3

      send_message_calls = Enum.filter(calls, fn {_, action, _} -> action == :send_message end)
      assert length(send_message_calls) == 3

      # Check order
      [call1, call2, call3] = send_message_calls
      {_, _, body1} = call1
      {_, _, body2} = call2
      {_, _, body3} = call3

      assert body1[:text] == "First message"
      assert body2[:text] == "Second message"
      assert body3[:text] == "Third message"
    end
  end
end
