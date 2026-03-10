defmodule <%= app_module %>.Bot do
  @bot <%= inspect(app) %>

  use ExGram.Bot,
    name: @bot,
    setup_commands: true

  command("start")
  command("help", description: "Print the bot's help")

  middleware(ExGram.Middleware.IgnoreUsername)

  @doc """
Handles the `/start` command by sending "Hi!" to the user and returning the updated context.

## Parameters

  - context: the handler context used to send the reply and continue processing.

## Returns

  - `{:ok, context}` with the updated context.
"""
@spec handle({:command, :start, any()}, map()) :: {:ok, map()}
def handle({:command, :start, _msg}, context) do
    answer(context, "Hi!")
  end

  def handle({:command, :help, _msg}, context) do
    answer(context, "Here is your help:")
  end
end
