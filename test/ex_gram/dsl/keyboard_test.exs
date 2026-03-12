defmodule ExGram.Dsl.KeyboardTest do
  use ExUnit.Case, async: true

  import ExGram.Dsl.Keyboard

  alias ExGram.Model.InlineKeyboardButton
  alias ExGram.Model.InlineKeyboardMarkup
  alias ExGram.Model.KeyboardButton
  alias ExGram.Model.ReplyKeyboardMarkup

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp inline_btn(text, opts \\ [])
  defp inline_btn(text, []), do: button(text, callback_data: text)
  defp inline_btn(text, opts), do: button(text, opts)

  defp reply_btn(text), do: reply_button(text)

  # ---------------------------------------------------------------------------
  # Inline keyboard – static DSL (regression tests for existing behaviour)
  # ---------------------------------------------------------------------------

  describe "keyboard :inline – static rows with row/do" do
    test "single row with one button" do
      kb =
        keyboard :inline do
          row do
            inline_btn("A")
          end
        end

      assert %InlineKeyboardMarkup{inline_keyboard: [[%InlineKeyboardButton{text: "A"}]]} = kb
    end

    test "single row with multiple buttons" do
      kb =
        keyboard :inline do
          row do
            inline_btn("A")
            inline_btn("B")
          end
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "A"}, %InlineKeyboardButton{text: "B"}]
               ]
             } = kb
    end

    test "multiple rows" do
      kb =
        keyboard :inline do
          row do
            inline_btn("A")
            inline_btn("B")
          end

          row do
            inline_btn("C")
          end
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "A"}, %InlineKeyboardButton{text: "B"}],
                 [%InlineKeyboardButton{text: "C"}]
               ]
             } = kb
    end
  end

  # ---------------------------------------------------------------------------
  # Inline keyboard – dynamic rows (the bug fix)
  # ---------------------------------------------------------------------------

  describe "keyboard :inline – dynamic rows via Enum.map" do
    test "Enum.map returning buttons produces a single row (pre-existing behaviour)" do
      # Each element of the map is a bare button → they're collected into one row
      kb =
        keyboard :inline do
          Enum.map([1, 2, 3, 4], fn x -> inline_btn(to_string(x)) end)
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [
                   %InlineKeyboardButton{text: "1"},
                   %InlineKeyboardButton{text: "2"},
                   %InlineKeyboardButton{text: "3"},
                   %InlineKeyboardButton{text: "4"}
                 ]
               ]
             } = kb
    end

    test "Enum.map returning [button] produces one row per element" do
      # Each element is a single-button list → each becomes its own row
      kb =
        keyboard :inline do
          Enum.map([1, 2, 3, 4], fn x -> [inline_btn(to_string(x))] end)
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "1"}],
                 [%InlineKeyboardButton{text: "2"}],
                 [%InlineKeyboardButton{text: "3"}],
                 [%InlineKeyboardButton{text: "4"}]
               ]
             } = kb
    end

    test "Enum.map returning multi-button rows" do
      # Each element is a list of two buttons → each list is one row
      kb =
        keyboard :inline do
          Enum.map([{"A", "a"}, {"B", "b"}], fn {label, data} ->
            [inline_btn(label, callback_data: data), inline_btn("x", callback_data: "x")]
          end)
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "A"}, %InlineKeyboardButton{text: "x"}],
                 [%InlineKeyboardButton{text: "B"}, %InlineKeyboardButton{text: "x"}]
               ]
             } = kb
    end

    test "mixed static row and dynamic Enum.map" do
      kb =
        keyboard :inline do
          row do
            inline_btn("Static")
          end

          Enum.map(["D1", "D2"], fn label -> [inline_btn(label)] end)
        end

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "Static"}],
                 [%InlineKeyboardButton{text: "D1"}],
                 [%InlineKeyboardButton{text: "D2"}]
               ]
             } = kb
    end

    test "the original bug report example – produces one row per number" do
      kb =
        keyboard :inline do
          Enum.map([1, 2, 3, 4], fn x -> [button(to_string(x), callback_data: to_string(x))] end)
        end

      assert %InlineKeyboardMarkup{inline_keyboard: rows} = kb
      assert length(rows) == 4
      assert Enum.all?(rows, fn [btn] -> %InlineKeyboardButton{} = btn end)
    end
  end

  # ---------------------------------------------------------------------------
  # Reply keyboard – static DSL (regression tests)
  # ---------------------------------------------------------------------------

  describe "keyboard :reply – static rows" do
    test "single row with one button" do
      kb =
        keyboard :reply do
          row do
            reply_btn("Yes")
          end
        end

      assert %ReplyKeyboardMarkup{keyboard: [[%KeyboardButton{text: "Yes"}]]} = kb
    end

    test "multiple rows" do
      kb =
        keyboard :reply do
          row do
            reply_btn("Yes")
            reply_btn("No")
          end

          row do
            reply_btn("Cancel")
          end
        end

      assert %ReplyKeyboardMarkup{
               keyboard: [
                 [%KeyboardButton{text: "Yes"}, %KeyboardButton{text: "No"}],
                 [%KeyboardButton{text: "Cancel"}]
               ]
             } = kb
    end
  end

  # ---------------------------------------------------------------------------
  # Reply keyboard – dynamic rows (the bug fix)
  # ---------------------------------------------------------------------------

  describe "keyboard :reply – dynamic rows via Enum.map" do
    test "Enum.map returning [button] produces one row per element" do
      kb =
        keyboard :reply do
          Enum.map(["Yes", "No", "Maybe"], fn label -> [reply_btn(label)] end)
        end

      assert %ReplyKeyboardMarkup{
               keyboard: [
                 [%KeyboardButton{text: "Yes"}],
                 [%KeyboardButton{text: "No"}],
                 [%KeyboardButton{text: "Maybe"}]
               ]
             } = kb
    end

    test "Enum.map returning buttons produces a single row" do
      kb =
        keyboard :reply do
          Enum.map(["Yes", "No"], fn label -> reply_btn(label) end)
        end

      assert %ReplyKeyboardMarkup{
               keyboard: [[%KeyboardButton{text: "Yes"}, %KeyboardButton{text: "No"}]]
             } = kb
    end
  end

  # ---------------------------------------------------------------------------
  # build_keyboard/3 – unit tests for normalize_rows edge cases
  # ---------------------------------------------------------------------------

  describe "build_keyboard/3 normalization" do
    test "nil rows are dropped" do
      kb = build_keyboard(:inline, [nil, [inline_btn("A")], nil], [])
      assert %InlineKeyboardMarkup{inline_keyboard: [[%InlineKeyboardButton{text: "A"}]]} = kb
    end

    test "empty list rows are dropped" do
      kb = build_keyboard(:inline, [[], [inline_btn("A")]], [])
      assert %InlineKeyboardMarkup{inline_keyboard: [[%InlineKeyboardButton{text: "A"}]]} = kb
    end

    test "bare button struct is wrapped as single-button row" do
      kb = build_keyboard(:inline, [inline_btn("A")], [])
      assert %InlineKeyboardMarkup{inline_keyboard: [[%InlineKeyboardButton{text: "A"}]]} = kb
    end

    test "list of button structs is a single row" do
      kb = build_keyboard(:inline, [[inline_btn("A"), inline_btn("B")]], [])

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "A"}, %InlineKeyboardButton{text: "B"}]
               ]
             } = kb
    end

    test "list of lists becomes multiple rows" do
      kb = build_keyboard(:inline, [[[inline_btn("A")], [inline_btn("B")]]], [])

      assert %InlineKeyboardMarkup{
               inline_keyboard: [
                 [%InlineKeyboardButton{text: "A"}],
                 [%InlineKeyboardButton{text: "B"}]
               ]
             } = kb
    end
  end
end
