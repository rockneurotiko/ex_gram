defmodule ExGram.Commands do
  @moduledoc """
  OLD. Can it be removed?
  """

  def handle_command(handler, %{text: t} = m) do
    if t == handler.cmd do
      handler.execute(m)
    end
  end
end
