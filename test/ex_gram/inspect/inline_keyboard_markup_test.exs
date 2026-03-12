defmodule ExGram.Inspect.InlineKeyboardMarkupTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.InlineKeyboardButton
  alias ExGram.Model.InlineKeyboardMarkup

  describe "Inspect InlineKeyboardMarkup" do
    test "renders a single row of plain buttons" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %InlineKeyboardButton{text: "1"},
            %InlineKeyboardButton{text: "2"},
            %InlineKeyboardButton{text: "3"}
          ]
        ]
      }

      assert inspect(markup) == """
             #InlineKeyboardMarkup<
               [ 1 ][ 2 ][ 3 ]
             >\
             """
    end

    test "renders multiple rows" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %InlineKeyboardButton{text: "1"},
            %InlineKeyboardButton{text: "2"}
          ],
          [
            %InlineKeyboardButton{text: "Back"},
            %InlineKeyboardButton{text: "Next"}
          ]
        ]
      }

      assert inspect(markup) == """
             #InlineKeyboardMarkup<
               [ 1 ][ 2 ]
               [ Back ][ Next ]
             >\
             """
    end

    test "renders action type abbreviation for callback_data" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %InlineKeyboardButton{text: "OK", callback_data: "ok"},
            %InlineKeyboardButton{text: "Cancel", callback_data: "cancel"}
          ]
        ]
      }

      assert inspect(markup) == """
             #InlineKeyboardMarkup<
               [ OK (cb) ][ Cancel (cb) ]
             >\
             """
    end

    test "renders url action type" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [%InlineKeyboardButton{text: "Visit", url: "https://example.com"}]
        ]
      }

      assert inspect(markup) == """
             #InlineKeyboardMarkup<
               [ Visit (url) ]
             >\
             """
    end

    test "renders mixed buttons with and without actions" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %InlineKeyboardButton{text: "1"},
            %InlineKeyboardButton{text: "2", callback_data: "btn_2"},
            %InlineKeyboardButton{text: "3", url: "https://example.com"}
          ]
        ]
      }

      assert inspect(markup) == """
             #InlineKeyboardMarkup<
               [ 1 ][ 2 (cb) ][ 3 (url) ]
             >\
             """
    end
  end

  describe "Inspect InlineKeyboardMarkup with verbose: true" do
    test "shows callback_data value when verbose" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %InlineKeyboardButton{text: "OK", callback_data: "ok_pressed"},
            %InlineKeyboardButton{text: "Cancel", callback_data: "cancel_action"}
          ]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #InlineKeyboardMarkup<
               [ OK (cb: "ok_pressed") ][ Cancel (cb: "cancel_action") ]
             >\
             """
    end

    test "shows url value when verbose" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [%InlineKeyboardButton{text: "Visit", url: "https://example.com"}]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #InlineKeyboardMarkup<
               [ Visit (url: "https://example.com") ]
             >\
             """
    end

    test "shows pay boolean value when verbose" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [%InlineKeyboardButton{text: "Pay now", pay: true}]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #InlineKeyboardMarkup<
               [ Pay now (pay: true) ]
             >\
             """
    end

    test "shows short struct name for struct-valued actions when verbose" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [%InlineKeyboardButton{text: "Open App", web_app: %ExGram.Model.WebAppInfo{url: "https://app.example.com"}}]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #InlineKeyboardMarkup<
               [ Open App (web_app: WebAppInfo) ]
             >\
             """
    end

    test "plain buttons without actions are unchanged when verbose" do
      markup = %InlineKeyboardMarkup{
        inline_keyboard: [
          [%InlineKeyboardButton{text: "1"}, %InlineKeyboardButton{text: "2"}]
        ]
      }

      assert inspect(markup, custom_options: [verbose: true]) == """
             #InlineKeyboardMarkup<
               [ 1 ][ 2 ]
             >\
             """
    end
  end
end
