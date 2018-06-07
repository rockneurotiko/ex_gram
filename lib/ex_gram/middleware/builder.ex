defmodule ExGram.Middleware.Builder do
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

    quote do
      @commands [command: unquote(command), name: unquote(name)]
    end
  end

  defmacro regex(regex, name, _opts \\ []) do
    quote do
      @regexes [regex: Regex.compile!(unquote(regex)), name: unquote(name)]
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    middlewares = Module.get_attribute(env.module, :middlewares) |> Enum.reverse()
    commands = Module.get_attribute(env.module, :commands) |> Enum.reverse()
    regexes = Module.get_attribute(env.module, :regexes) |> Enum.reverse()

    quote do
      defp middlewares(), do: unquote(middlewares)
      defp commands(), do: unquote(commands)
      defp regexes(), do: unquote(regexes)

      # Do it like plug and decompile all the core with the middlewares here?
    end
  end
end
