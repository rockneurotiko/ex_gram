defmodule ExGram.Dsl.KeyboardTest do
  use ExUnit.Case, async: true

  import ExGram.Dsl.Keyboard

  alias ExGram.Model.InlineKeyboardMarkup

  describe "keyboard/2 macro" do
    test "creates empty inline keyboard" do
      keyb =
        keyboard :inline do
        end

      assert %InlineKeyboardMarkup{inline_keyboard: []} = keyb
    end

    test "creates keyboard with single row and button" do
      keyb =
        keyboard :inline do
          row do
            button("Click me", callback_data: "clicked")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [button] = row
      assert %ExGram.Model.InlineKeyboardButton{} = button
      assert button.text == "Click me"
      assert button.callback_data == "clicked"
    end

    test "creates keyboard with multiple buttons in one row" do
      keyb =
        keyboard :inline do
          row do
            button("A", callback_data: "a")
            button("B", callback_data: "b")
            button("C", callback_data: "c")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert length(row) == 3
      assert Enum.at(row, 0).text == "A"
      assert Enum.at(row, 1).text == "B"
      assert Enum.at(row, 2).text == "C"
    end

    test "creates keyboard with multiple rows" do
      keyb =
        keyboard :inline do
          row do
            button("A", callback_data: "a")
            button("B", callback_data: "b")
          end

          row do
            button("C", callback_data: "c")
            button("D", callback_data: "d")
          end

          row do
            button("E", callback_data: "e")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: rows} = keyb
      assert length(rows) == 3
      assert length(Enum.at(rows, 0)) == 2
      assert length(Enum.at(rows, 1)) == 2
      assert length(Enum.at(rows, 2)) == 1
    end

    test "creates keyboard with url buttons" do
      keyb =
        keyboard :inline do
          row do
            button("Visit", url: "https://example.com")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [button] = row
      assert button.text == "Visit"
      assert button.url == "https://example.com"
    end

    test "creates keyboard with mixed button types" do
      keyb =
        keyboard :inline do
          row do
            button("Callback", callback_data: "cb_data")
            button("URL", url: "https://example.com")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [btn1, btn2] = row
      assert btn1.callback_data == "cb_data"
      assert btn2.url == "https://example.com"
    end

    test "creates complex keyboard layout" do
      keyb =
        keyboard :inline do
          row do
            button("1", callback_data: "1")
            button("2", callback_data: "2")
            button("3", callback_data: "3")
          end

          row do
            button("4", callback_data: "4")
            button("5", callback_data: "5")
          end

          row do
            button("Back", callback_data: "back")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: rows} = keyb
      assert length(rows) == 3
      # First row has 3 buttons
      assert length(Enum.at(rows, 0)) == 3
      # Second row has 2 buttons
      assert length(Enum.at(rows, 1)) == 2
      # Third row has 1 button
      assert length(Enum.at(rows, 2)) == 1
    end
  end

  describe "button/2 macro" do
    test "creates button with text only" do
      keyb =
        keyboard :inline do
          row do
            button("Text only")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [button] = row
      assert button.text == "Text only"
    end

    test "creates button with callback_data" do
      keyb =
        keyboard :inline do
          row do
            button("Click", callback_data: "action_click")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [button] = row
      assert button.text == "Click"
      assert button.callback_data == "action_click"
    end

    test "creates button with url" do
      keyb =
        keyboard :inline do
          row do
            button("Link", url: "https://telegram.org")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [row]} = keyb
      assert [button] = row
      assert button.text == "Link"
      assert button.url == "https://telegram.org"
    end
  end
end
