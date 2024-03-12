defmodule Test.Support.StringGenerator do
  @moduledoc """
  Test helper to generate random strings
  """

  @chars String.codepoints("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

  def string_of_length(length) do
    1..length
    |> Enum.reduce([], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end
end
