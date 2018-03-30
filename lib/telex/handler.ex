defmodule Telex.Handler do
  @callback handle(any, Telex.Cnt.t()) :: Telex.Cnt.t()
end
