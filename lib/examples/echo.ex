defmodule Examples.Echo do
  use Telex.Dsl.Command, "echo"
  use Telex.Dsl

  require Logger

  def execute(%{text: t} = msg) do
    Logger.debug "Executing echo on #{inspect(msg)}"
    answer msg, t, bot: :simple_bot
  end
end
