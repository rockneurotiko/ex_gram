defmodule ExGram.Inspect.ReplyKeyboardMarkupTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.KeyboardButton
  alias ExGram.Model.ReplyKeyboardMarkup

  describe "Inspect ReplyKeyboardMarkup" do
    test "renders a single row with no options" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [
          [
            %KeyboardButton{text: "Option A"},
            %KeyboardButton{text: "Option B"}
          ]
        ]
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<
               [ Option A ][ Option B ]
             >\
             """
    end

    test "renders multiple rows with no options" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [
          [%KeyboardButton{text: "Option A"}, %KeyboardButton{text: "Option B"}],
          [%KeyboardButton{text: "Option C"}]
        ]
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<
               [ Option A ][ Option B ]
               [ Option C ]
             >\
             """
    end

    test "shows resize option before rows" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Go"}]],
        resize_keyboard: true
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<resize: true,
               [ Go ]
             >\
             """
    end

    test "shows multiple options before rows" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Go"}]],
        resize_keyboard: true,
        one_time_keyboard: true
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<resize: true, one_time: true,
               [ Go ]
             >\
             """
    end

    test "shows is_persistent option with short name" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Go"}]],
        is_persistent: true
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<persistent: true,
               [ Go ]
             >\
             """
    end

    test "shows placeholder option with value" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Go"}]],
        input_field_placeholder: "Type here..."
      }

      assert inspect(markup) == """
             #ReplyKeyboardMarkup<placeholder: "Type here...",
               [ Go ]
             >\
             """
    end
  end
end
