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

      # Start default test adapter if not already started
      case Test.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      {:ok, name: name}
    end

    test "test random", %{name: name} do
      # Test with named adapter
      Test.backdoor_request("/getMe", %{username: "rock"}, name)
      assert {:ok, %{username: "rock"}} == Test.request(:get, "/getMe", "", name)

      # Test with default adapter
      Test.backdoor_request("/getMe", %{username: "rock"})
      user = %User{username: "rock"}
      assert {:ok, user} == ExGram.get_me()
    end
  end
end
