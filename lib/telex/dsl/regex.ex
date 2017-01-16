defmodule Telex.Dsl.Regex do
  defmacro regex(name, regex, callback) do
    mname = Telex.Dsl.Base.module_name __MODULE__, name

    quote do
      defmodule unquote(mname) do
        use Telex.Dsl.Regex, unquote(regex)

        def execute(msg), do: unquote(callback).(msg)
      end

      @dispatchers unquote(mname)
    end
  end

  defmacro regex(name, regex, module, do: block) do
    fname = Telex.Dsl.Base.extract_name(name) |> String.downcase |> String.to_atom

    quote do
      def unquote(fname)(var!(msg)), do: unquote(block)

      regex unquote(name), unquote(regex), &unquote(module).unquote(fname)/1
    end
  end

  defmacro __using__(cmd) do
    quote do
      @behaviour Telex.Dsl.Message

      @reg Regex.compile!(unquote(cmd))

      def test(%{text: t}), do: Regex.match?(@reg, t)
      def test(_), do: false
    end
  end
end
