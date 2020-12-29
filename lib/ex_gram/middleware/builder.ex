defmodule ExGram.Middleware.Builder do
  @moduledoc """
  Macros for building bot settings like middlewares, commands and regex
  """

  defmacro __using__(_opts) do
    quote do
      import ExGram.Middleware.Builder,
        only: [middleware: 1, middleware: 2, command: 1, command: 2, regex: 2, regex: 3]

      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      Module.register_attribute(__MODULE__, :regexes, accumulate: true)

      @before_compile ExGram.Middleware.Builder
    end
  end

  defmacro middleware(middleware, opts \\ []) do
    quote do
      @middlewares {unquote(middleware), unquote(opts)}
    end
  end

  defmacro command(command, opts \\ []) do
    name = Keyword.get(opts, :name, String.to_atom(command))
    description = Keyword.get(opts, :description)

    quote do
      @commands [
        command: unquote(command),
        name: unquote(name),
        description: unquote(description)
      ]
    end
  end

  defmacro regex(regex, name, _opts \\ []) do
    quote do
      @regexes [
        regex: ExGram.Middleware.Builder.compile_regex(unquote(regex)),
        name: unquote(name)
      ]
    end
  end

  def compile_regex(%{__struct__: Regex} = regex), do: regex
  def compile_regex(binary) when is_binary(binary), do: Regex.compile!(binary)

  @doc false
  defmacro __before_compile__(env) do
    middlewares =
      Module.get_attribute(env.module, :middlewares) |> Enum.reverse() |> Macro.escape()

    commands = Module.get_attribute(env.module, :commands) |> Enum.reverse() |> Macro.escape()
    regexes = Module.get_attribute(env.module, :regexes) |> Enum.reverse() |> Macro.escape()

    quote do
      def middlewares(), do: unquote(middlewares)
      def commands(), do: unquote(commands)
      def regexes(), do: unquote(regexes)

      # Do it like plug and decompile all the core with the middlewares here?
    end
  end
end
