defmodule Simple do
  use Telex.Bot

  command Echo

  def test() do
    IO.inspect @commands
  end
end

Simple.test
