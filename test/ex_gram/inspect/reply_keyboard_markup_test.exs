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
               [ [ Option A ][ Option B ] ]
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
               [ [ Option A ][ Option B ] ]
               [ [ Option C ] ]
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
               [ [ Go ] ]
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
               [ [ Go ] ]
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
               [ [ Go ] ]
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
               [ [ Go ] ]
             >\
             """
    end
  end

  describe "Inspect ReplyKeyboardMarkup with verbose: true" do
    test "plain buttons show no extra info when no optional fields set" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Help"}, %KeyboardButton{text: "Settings"}]]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<
               [ [ Help ][ Settings ] ]
             >\
             """
    end

    test "shows request_contact when verbose" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Share Contact", request_contact: true}]]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<
               [ [ Share Contact (request_contact: true) ] ]
             >\
             """
    end

    test "shows request_location when verbose" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Share Location", request_location: true}]]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<
               [ [ Share Location (request_location: true) ] ]
             >\
             """
    end

    test "shows style when verbose" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Cancel", style: "danger"}]]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<
               [ [ Cancel (style: "danger") ] ]
             >\
             """
    end

    test "shows multiple button fields when verbose" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [
          [
            %KeyboardButton{text: "Go", request_location: true},
            %KeyboardButton{text: "Contact", request_contact: true}
          ]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<
               [ [ Go (request_location: true) ][ Contact (request_contact: true) ] ]
             >\
             """
    end

    test "combines markup options with verbose button detail" do
      markup = %ReplyKeyboardMarkup{
        keyboard: [[%KeyboardButton{text: "Share", request_contact: true}]],
        resize_keyboard: true
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #ReplyKeyboardMarkup<resize: true,
               [ [ Share (request_contact: true) ] ]
             >\
             """
    end
  end
end
