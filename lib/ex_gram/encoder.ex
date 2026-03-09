defmodule ExGram.Encoder do
  @moduledoc """
  JSON encoder/decoder abstraction with pluggable engine support.

  By default uses [Jason](https://hexdocs.pm/jason). The engine is compiled at
  compile time for performance. Provides `encode/1-2`, `encode!/1-2`, `decode/1-2`,
  and `decode!/1-2` functions that delegate to the selected engine.
  """

  alias __MODULE__.Engine

  defmodule Engine do
    @moduledoc """
    Compiled encoder engine module.

    This module is recompiled at compile time to return the configured engine.
    The initial `nil` return value is a placeholder before recompilation.
    """

    def engine, do: nil
  end

  defmodule EngineCompiler do
    @moduledoc """
    Dynamically compiles the `ExGram.Encoder.Engine` module with the selected engine.

    This allows the engine backend to be defined at compile time without reading from
    application config on every call.
    """

    def compile(engine) do
      Code.compiler_options(ignore_module_conflict: true)

      quote_result =
        quote bind_quoted: [engine: engine], location: :keep do
          defmodule Elixir.ExGram.Encoder.Engine do
            @moduledoc """
            Compiled encoder engine
            """
            def engine do
              unquote(engine)
            end
          end
        end

      Code.eval_quoted(quote_result, [], __ENV__)
      Code.compiler_options(ignore_module_conflict: false)
      :ok
    end
  end

  @default_engine Jason
  __MODULE__.EngineCompiler.compile(@default_engine)

  defp engine do
    Engine.engine()
  end

  def encode(data, opts \\ []) do
    engine().encode(data, opts)
  end

  def encode!(data, opts \\ []) do
    engine().encode!(data, opts)
  end

  def decode(data, opts \\ []) do
    engine().decode(data, opts)
  end

  def decode!(data, opts \\ []) do
    engine().decode!(data, opts)
  end
end
