defmodule Telex.Dsl.Message do
  import Telex.Dsl.Base

  @callback test(Telex.Model.Message.t()) :: boolean
  @callback execute(Telex.Model.Message.t()) :: any

  defmacro message(name, callback) do
    module_callback(name, Telex.Dsl.Message, callback)
  end

  defmacro message(name, module, do: block) do
    module_do_macro(name, module, block, :message, :msg)
  end

  defmacro __using__(_) do
    quote do
      @behaviour Telex.Dsl.Message

      def test(_), do: true

      def execute(m) when not is_nil(m), do: execute(m)
    end
  end
end
