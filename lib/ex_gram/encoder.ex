defmodule ExGram.Encoder do
  @moduledoc """
  JSON encoder/decoder abstraction with pluggable engine support.

  By default uses [Jason](https://hexdocs.pm/jason). The engine is compiled at
  compile time for performance. Provides `encode/1-2`, `encode!/1-2`, `decode/1-2`,
  and `decode!/1-2` functions that delegate to the selected engine.
  """

  alias __MODULE__.Engine

  defmodule Engine do
    @doc """
Returns the configured JSON engine module or a placeholder.

This function yields the module used for JSON encoding/decoding; it may be `nil` before the engine is compiled into the module.
"""
@spec engine() :: module() | nil

    def engine, do: nil
  end

  defmodule EngineCompiler do
    @doc """
    Compile the ExGram.Encoder.Engine module to use the given JSON engine at compile time.
    
    Generates a concrete Elixir.ExGram.Encoder.Engine module whose `engine/0` returns the provided `engine` module, embedding the selected backend into compiled code.
    
    ## Parameters
    
      - engine: Module that implements the JSON encoder/decoder API used by ExGram (e.g., `Jason`).
    
    @returns
      - `:ok` on success.
    """
    @spec compile(module()) :: :ok

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
