defmodule Telex.Dsl.Command do
  defmacro __using__(cmd) do
    quote do
      @behaviour Telex.Dsl.Base

      import Telex.Dsl

      @reg Regex.compile!("/#{unquote(cmd)} ?.*")

      def test(%{message: %{text: t}}), do: Regex.match?(@reg, t)
      def test(_), do: false

      def execute(%{message: m}) when not is_nil(m), do: execute(m)
    end
  end
end
