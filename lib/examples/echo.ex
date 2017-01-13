defmodule Examples.Echo do
  use Telex.Dsl.Command, "echo"

  require Logger

  def execute(%{text: t} = msg) do
    Logger.debug "Executing echo on #{inspect(msg)}"
    answer msg, t
  end
end
