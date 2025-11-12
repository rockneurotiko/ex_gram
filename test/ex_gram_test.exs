defmodule ExGramTest do
  use ExUnit.Case, async: false

  import Test.Support.StringGenerator

  alias ExGram.Adapter.Test
  alias ExGram.Model.User

  doctest ExGram

  test "the truth" do
    assert 1 + 1 == 2
  end

  describe "a" do
    setup do
      name = 10 |> string_of_length() |> String.to_atom()
      {:ok, _} = Test.start_link(name: name)
      Test.start_link([])

      {:ok, name: name}
    end

    test "test random", %{name: name} do
      Test.backdoor_request("/getMe", %{username: "rock"}, name)
      assert {:ok, %{username: "rock"}} == Test.request(:get, "/getMe", "", name)

      Test.backdoor_request("/getMe", %{username: "rock"})
      user = %User{username: "rock"}
      assert {:ok, user} == ExGram.get_me()
    end
  end
end
