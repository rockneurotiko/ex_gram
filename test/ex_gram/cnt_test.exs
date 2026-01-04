defmodule ExGram.CntTest do
  use ExUnit.Case, async: true

  alias ExGram.Cnt
  alias ExGram.Model.{Update, User}

  describe "new/1" do
    test "creates new context with default values" do
      cnt = Cnt.new()

      assert %Cnt{} = cnt
      assert cnt.name == nil
      assert cnt.bot_info == nil
      assert cnt.update == nil
      assert cnt.message == nil
      assert cnt.halted == false
      assert cnt.middlewares == []
      assert cnt.middleware_halted == false
      assert cnt.commands == []
      assert cnt.regex == []
      assert cnt.answers == []
      assert cnt.responses == []
      assert cnt.extra == %{}
    end

    test "creates new context with custom extra fields" do
      cnt = Cnt.new(%{name: :test_bot})

      assert %Cnt{} = cnt
      assert cnt.name == :test_bot
    end

    test "merges extra map into new context" do
      extra = %{
        name: :my_bot,
        bot_info: %User{id: 123},
        halted: true,
        extra: %{custom: "data"}
      }

      cnt = Cnt.new(extra)

      assert cnt.name == :my_bot
      assert cnt.bot_info == %User{id: 123}
      assert cnt.halted == true
      assert cnt.extra == %{custom: "data"}
    end

    test "preserves all default fields when creating with empty map" do
      cnt = Cnt.new(%{})

      assert %Cnt{
               name: nil,
               bot_info: nil,
               update: nil,
               halted: false,
               middlewares: [],
               commands: [],
               regex: [],
               answers: [],
               responses: [],
               extra: %{}
             } = cnt
    end
  end

  describe "Cnt struct" do
    test "can be created with struct syntax" do
      cnt = %Cnt{name: :bot, halted: true}

      assert cnt.name == :bot
      assert cnt.halted == true
    end

    test "can be updated" do
      cnt = Cnt.new()
      updated = %{cnt | name: :updated_bot, halted: true}

      assert updated.name == :updated_bot
      assert updated.halted == true
    end

    test "can store update" do
      update = %Update{update_id: 123}
      cnt = %Cnt{update: update}

      assert cnt.update.update_id == 123
    end

    test "can store bot_info" do
      bot_info = %User{id: 456, username: "test_bot"}
      cnt = %Cnt{bot_info: bot_info}

      assert cnt.bot_info.id == 456
      assert cnt.bot_info.username == "test_bot"
    end

    test "can store custom data in extra" do
      cnt = %Cnt{extra: %{session_id: "abc123", user_data: %{score: 100}}}

      assert cnt.extra.session_id == "abc123"
      assert cnt.extra.user_data.score == 100
    end
  end
end
