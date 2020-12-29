defmodule Test.Support.StringGenerator do
  @moduledoc """
  Test helper to generate random strings
  """

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints()

  def string_of_length(length) do
    Enum.reduce(1..length, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
