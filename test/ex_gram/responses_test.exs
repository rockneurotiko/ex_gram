defmodule ExGram.ResponsesTest do
  use ExUnit.Case, async: true

  alias ExGram.Responses

  describe "Responses protocol for Atom" do
    test "new/2 creates struct from atom and params" do
      result = Responses.new(ExGram.Model.User, %{id: 123, username: "test"})
      assert %ExGram.Model.User{id: 123, username: "test"} = result
    end

    test "new/2 with empty params creates empty struct" do
      result = Responses.new(ExGram.Model.User, %{})
      assert %ExGram.Model.User{} = result
    end

    test "execute/1 raises not implemented for atom" do
      assert_raise RuntimeError, "Not implemented", fn ->
        Responses.execute(:some_atom)
      end
    end

    test "set_msg/2 raises not implemented for atom" do
      assert_raise RuntimeError, "Not implemented", fn ->
        Responses.set_msg(:some_atom, %{})
      end
    end
  end
end
