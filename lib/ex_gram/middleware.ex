defmodule ExGram.Middleware do
  @moduledoc """
  Behaviour for creating middlewares.

  Middlewares receive the context (`ExGram.Cnt`) and can modify it before passing
  it to the next middleware or handler. Use middlewares for authentication, logging,
  rate limiting, or enriching the context with additional data.

  See the [Middlewares](middlewares.md) guide for usage examples.
  """

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @callback init(opts) :: opts
  @optional_callbacks init: 1

  @callback call(ExGram.Cnt.t(), opts) :: ExGram.Cnt.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour ExGram.Middleware

      import ExGram.Middleware, only: [add_extra: 2, add_extra: 3, halt: 1]

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
