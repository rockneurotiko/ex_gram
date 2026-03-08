defmodule ExGram.Middleware.Builder do
  @moduledoc """
  Macros for building bot settings like middlewares, commands and regex
  """

  defmacro __using__(_opts) do
    quote do
      import ExGram.Middleware.Builder,
        only: [middleware: 1, middleware: 2, command: 1, command: 2, regex: 2, regex: 3]

      @before_compile ExGram.Middleware.Builder

      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      Module.register_attribute(__MODULE__, :regexes, accumulate: true)
    end
  end

  defmacro middleware(middleware, opts \\ []) do
    quote do
      @middlewares {unquote(middleware), unquote(opts)}
    end
  end

  defmacro command(command, opts \\ []) do
    {command_str, default_name} =
      if is_atom(command) do
        {Atom.to_string(command), command}
      else
        {command, String.to_atom(command)}
      end

    name = Keyword.get(opts, :name, default_name)
    opts = Keyword.delete(opts, :name)

    quote do
      @commands [
        command: unquote(command_str),
        name: unquote(name),
        opts: unquote(opts)
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
      env.module |> Module.get_attribute(:middlewares) |> Enum.reverse() |> Macro.escape()

    commands = env.module |> Module.get_attribute(:commands) |> Enum.reverse()
    ExGram.Bot.ValidateCommands.validate!(commands)
    commands = Macro.escape(commands)

    regexes = env.module |> Module.get_attribute(:regexes) |> Enum.reverse() |> Macro.escape()

    quote do
      def middlewares, do: unquote(middlewares)
      def commands, do: unquote(commands)
      def regexes, do: unquote(regexes)
    end
  end
end
