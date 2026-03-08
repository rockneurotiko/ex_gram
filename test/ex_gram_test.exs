defmodule ExGramTest do
  use ExUnit.Case, async: false

  import Test.Support.StringGenerator

  alias ExGram.Adapter.Test

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
  end
end
