defmodule TelexTest do
  use ExUnit.Case, async: false
  doctest Telex

  import Test.Support.StringGenerator

  test "the truth" do
    assert 1 + 1 == 2
  end

  describe "a" do
    setup do
      name = string_of_length(10) |> String.to_atom()
      {:ok, _} = Telex.Adapter.Test.start_link(name: name)
      Telex.Adapter.Test.start_link([])

      {:ok, name: name}
    end

    test "test random", %{name: name} do
      Telex.Adapter.Test.backdoor_request("/getMe", %{username: "rock"}, name)
      Telex.Adapter.Test.request(:get, "/getMe", "", name) |> IO.inspect()

      Telex.Adapter.Test.backdoor_request("/getMe", %{username: "rock"})
      Telex.get_me() |> IO.inspect()
    end
  end
end
