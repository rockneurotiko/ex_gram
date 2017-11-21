defmodule Telex.Dsl.Command do
  defmacro command(name, regex, callback) do
    mname = Telex.Dsl.Base.module_name(__MODULE__, name)

    quote do
      defmodule unquote(mname) do
        use Telex.Dsl.Command, unquote(regex)

        def execute(msg), do: unquote(callback).(msg)
      end

      @dispatchers unquote(mname)
    end
  end

  defmacro command(name, regex, module, do: block) do
    fname = Telex.Dsl.Base.extract_name(name) |> String.downcase() |> String.to_atom()

    quote do
      def unquote(fname)(var!(msg)), do: unquote(block)

      command(unquote(name), unquote(regex), &(unquote(module).unquote(fname) / 1))
    end
  end

  defmacro __using__(cmd) do
    quote do
      use Telex.Dsl.Regex, "/#{unquote(cmd)} ?.*"
    end
  end
end
