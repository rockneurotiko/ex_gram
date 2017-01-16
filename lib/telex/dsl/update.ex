defmodule Telex.Dsl.Update do
  import Telex.Dsl.Base

  defmacro update(name, callback) do
    module_callback(name, Telex.Dsl.Update, callback)
  end

  defmacro update(name, module, do: block) do
    module_do_macro(name, module, block, :update, :update)
  end

  defmacro __using__(_) do
    quote do
      @behaviour Telex.Dsl.Base

      def test(_), do: true
    end
  end
end
