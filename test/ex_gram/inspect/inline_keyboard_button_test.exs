defmodule ExGram.Inspect.InlineKeyboardButtonTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.InlineKeyboardButton

  describe "Inspect InlineKeyboardButton" do
    test "shows text only when no action fields are set" do
      button = %InlineKeyboardButton{text: "Click me"}
      assert inspect(button) == ~s(#InlineKeyboardButton<"Click me">)
    end

    test "shows callback_data action" do
      button = %InlineKeyboardButton{text: "OK", callback_data: "ok_pressed"}
      assert inspect(button) == ~s(#InlineKeyboardButton<"OK" callback_data: "ok_pressed">)
    end

    test "shows url action" do
      button = %InlineKeyboardButton{text: "Visit", url: "https://example.com"}
      assert inspect(button) == ~s(#InlineKeyboardButton<"Visit" url: "https://example.com">)
    end

    test "shows style when set" do
      button = %InlineKeyboardButton{text: "Delete", style: "danger"}
      assert inspect(button) == ~s(#InlineKeyboardButton<"Delete" style: "danger">)
    end

    test "shows pay action" do
      button = %InlineKeyboardButton{text: "Pay", pay: true}
      assert inspect(button) == ~s(#InlineKeyboardButton<"Pay" pay: true>)
    end

    test "shows multiple non-nil fields" do
      button = %InlineKeyboardButton{text: "Buy", style: "primary", callback_data: "buy"}
      assert inspect(button) == ~s(#InlineKeyboardButton<"Buy" style: "primary", callback_data: "buy">)
    end
  end
end
