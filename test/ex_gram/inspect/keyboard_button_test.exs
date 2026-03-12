defmodule ExGram.Inspect.KeyboardButtonTest do
  use ExUnit.Case, async: true

  alias ExGram.Model.KeyboardButton

  describe "Inspect KeyboardButton" do
    test "shows text only when no optional fields are set" do
      button = %KeyboardButton{text: "Send"}
      assert inspect(button) == ~s(#KeyboardButton<"Send">)
    end

    test "shows request_contact when true" do
      button = %KeyboardButton{text: "Share Contact", request_contact: true}
      assert inspect(button) == ~s(#KeyboardButton<"Share Contact" request_contact: true>)
    end

    test "shows request_location when true" do
      button = %KeyboardButton{text: "Share Location", request_location: true}
      assert inspect(button) == ~s(#KeyboardButton<"Share Location" request_location: true>)
    end

    test "shows style when set" do
      button = %KeyboardButton{text: "Cancel", style: "danger"}
      assert inspect(button) == ~s(#KeyboardButton<"Cancel" style: "danger">)
    end

    test "shows multiple non-nil fields" do
      button = %KeyboardButton{text: "Action", style: "primary", request_contact: true}
      assert inspect(button) == ~s(#KeyboardButton<"Action" style: "primary", request_contact: true>)
    end
  end
end
