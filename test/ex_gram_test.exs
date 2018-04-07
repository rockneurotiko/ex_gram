defmodule ExGramTest do
  use ExUnit.Case, async: false
  doctest ExGram

  import Test.Support.StringGenerator

  test "the truth" do
    assert 1 + 1 == 2
  end

  describe "a" do
    setup do
      name = string_of_length(10) |> String.to_atom()
      {:ok, _} = ExGram.Adapter.Test.start_link(name: name)
      ExGram.Adapter.Test.start_link([])

      {:ok, name: name}
    end

    test "test random", %{name: name} do
      ExGram.Adapter.Test.backdoor_request("/getMe", %{username: "rock"}, name)
      ExGram.Adapter.Test.request(:get, "/getMe", "", name) |> IO.inspect()

      ExGram.Adapter.Test.backdoor_request("/getMe", %{username: "rock"})
      ExGram.get_me() |> IO.inspect()
    end
  end
end
