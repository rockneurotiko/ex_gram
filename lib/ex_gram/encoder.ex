defmodule ExGram.Encoder do
  @moduledoc """
  Helper module to encode/decode json
  """

  defmodule Engine do
    @moduledoc """
    By default we will return nil, which will cause to use the default engine
    """

    def engine(), do: nil
  end

  alias __MODULE__.Engine

  defmodule EngineCompiler do
    @moduledoc """
    This will reload the ExGram.Encoder.Engine module with the engine selected.

    With this we allow to define dynamically the engine backend while not having
    to read it from the Application everytime.
    """

    def compile(engine) do
      Code.compiler_options(ignore_module_conflict: true)

      quote bind_quoted: [engine: engine], location: :keep do
        defmodule Elixir.ExGram.Encoder.Engine do
          @moduledoc """
          Compiled encoder engine
          """
          def engine() do
            unquote(engine)
          end
        end
      end
      |> Code.eval_quoted([], __ENV__)

      Code.compiler_options(ignore_module_conflict: false)
      :ok
    end
  end

  @default_engine Jason

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

  defp engine() do
    Engine.engine() || @default_engine
  end
end
