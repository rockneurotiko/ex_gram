defmodule Echo do
  def cmd(), do: "/test"

  def execute() do
    IO.puts "EXECUTING"
  end
end
