defmodule ExGram.Handler do
  @callback handle(any, ExGram.Cnt.t()) :: ExGram.Cnt.t()
end
