defmodule ExGram.Commands do
  def handle_command(handler, %{text: t} = m) do
    if t == handler.cmd do
      handler.execute(m)
    end
  end
end
