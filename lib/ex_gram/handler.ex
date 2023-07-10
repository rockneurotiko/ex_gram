defmodule ExGram.Handler do
  @moduledoc """
  Handle behaviour for ExGram.Bot implementation
  """

  @callback handle(ExGram.Dispatcher.parsed_message(), ExGram.Cnt.t()) :: ExGram.Cnt.t()
  @callback handle_error(ExGram.Error.t()) :: any

  @optional_callbacks handle: 2, handle_error: 1
end
