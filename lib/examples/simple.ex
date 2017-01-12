defmodule Examples.Simple do
  use Telex.Bot, :updates

  command Examples.Echo

  def test() do
    IO.inspect @commands
  end
end
