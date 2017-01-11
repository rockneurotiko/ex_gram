defmodule Telex.Bot do
  defmacro __using__(_) do
    quote do
      import Telex.Commands

      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      # @before_compile Telex.Bot
    end
  end
end
