defmodule ExGram.Middleware do
  @moduledoc """
  Helper to make it easier to create middlewares
  """

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @callback init(opts) :: opts
  @optional_callbacks init: 1

  @callback call(ExGram.Cnt.t(), opts) :: ExGram.Cnt.t()

  defmacro __using__(_opts) do
    quote do
      import ExGram.Middleware, only: [add_extra: 2, add_extra: 3, halt: 1]

      @behaviour ExGram.Middleware

      def init(opts), do: opts
      defoverridable ExGram.Middleware
    end
  end

  def add_extra(%ExGram.Cnt{extra: extra} = cnt, values) when is_map(values) do
    %{cnt | extra: Map.merge(extra, values)}
  end

  def add_extra(%ExGram.Cnt{extra: extra} = cnt, key, value) do
    %{cnt | extra: Map.put(extra, key, value)}
  end

  def halt(%ExGram.Cnt{} = cnt) do
    %{cnt | middleware_halted: true}
  end
end
