defmodule Telex.Middleware do
  @moduledoc """
  Allow creating middlewares
  """

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @callback init(opts) :: opts
  @optional_callbacks init: 1

  @callback call(Telex.Cnt.t(), opts) :: Telex.Cnt.t()

  defmacro __using__(_opts) do
    quote do
      import Telex.Middleware, only: [add_extra: 2, add_extra: 3]

      @behaviour Telex.Middleware

      def init(opts), do: opts
      defoverridable Telex.Middleware
    end
  end

  def add_extra(%Telex.Cnt{extra: extra} = cnt, values) when is_map(values) do
    %{cnt | extra: Map.merge(extra, values)}
  end

  def add_extra(%Telex.Cnt{extra: extra} = cnt, key, value) do
    %{cnt | extra: Map.put(extra, key, value)}
  end
end
