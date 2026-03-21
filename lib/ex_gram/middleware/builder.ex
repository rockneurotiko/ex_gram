defmodule ExGram.Middleware.Builder do
  @moduledoc """
  Macros for building bot middleware chains, commands, regex patterns, and init hooks.

  This module provides a DSL for declaratively configuring bot behavior using module
  attributes. Use `use ExGram.Middleware.Builder` in your bot module to access the
  `middleware/1-2`, `command/1-2`, `regex/2-3`, and `on_bot_init/1-2` macros.

  At compile time, these declarations are collected and exposed via `middlewares/0`,
  `commands/0`, `regexes/0`, and `bot_inits/0` functions.

  See the [Middlewares guide](middlewares.md) for usage examples.
  """

  defmacro __using__(_opts) do
    quote do
      import ExGram.Middleware.Builder,
        only: [
          middleware: 1,
          middleware: 2,
          command: 1,
          command: 2,
          regex: 2,
          regex: 3,
          on_bot_init: 1,
          on_bot_init: 2
        ]

      @before_compile ExGram.Middleware.Builder

      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)
      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      Module.register_attribute(__MODULE__, :regexes, accumulate: true)
      Module.register_attribute(__MODULE__, :bot_inits, accumulate: true)
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

  defmacro on_bot_init(module, opts \\ []) do
    quote do
      @bot_inits {unquote(module), unquote(opts)}
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

    bot_inits =
      env.module |> Module.get_attribute(:bot_inits) |> Enum.reverse() |> Macro.escape()

    quote do
      def middlewares, do: unquote(middlewares)
      def commands, do: unquote(commands)
      def regexes, do: unquote(regexes)
      def bot_inits, do: unquote(bot_inits)
    end
  end
end
