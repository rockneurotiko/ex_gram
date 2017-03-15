defmodule Telex.Dsl.Handler do
  @callback handle(any, any, map) :: any
end
