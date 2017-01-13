defmodule Telex.Dsl.Base do
  @callback test(Telex.Model.Update.t) :: boolean
  @callback execute(map) :: any
end
