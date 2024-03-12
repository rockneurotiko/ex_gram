defmodule Examples.Simple do
  @moduledoc false

  use ExGram.Bot, name: @bot, setup_commands: true

  require Logger

  @bot :simple_bot

  command("echo", description: "Echo the message back to the user")

  middleware(ExGram.Middleware.IgnoreUsername)

  def handle({:command, :echo, %{text: t}}, cnt) do
    answer(cnt, t)
  end

  def handle({:bot_message, from, msg}, %{name: name}) do
    Logger.info("Message from bot #{inspect(from)} to #{inspect(name)}  : #{inspect(msg)}")
    :hi
  end

  def handle(msg, _) do
    IO.puts("Unknown message #{inspect(msg)}")
  end
end
