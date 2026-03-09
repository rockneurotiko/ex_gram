defmodule ExGram.Handler do
  @moduledoc """
  Behaviour for handling updates in `ExGram.Bot` implementations.

  Implement this behaviour in your bot module to handle incoming updates from Telegram.
  The `c:handle/2` callback receives parsed messages and a context struct, while
  `c:handle_error/1` handles any errors that occur during message processing.

  See the [Handling Updates guide](handling-updates.md) for more details.
  """

  @callback handle(ExGram.Dispatcher.parsed_message(), ExGram.Cnt.t()) :: ExGram.Cnt.t()
  @callback handle_error(ExGram.Error.t()) :: any

  @type init_opts :: [bot: atom() | String.t(), token: String.t()]
  @callback init(init_opts) :: :ok

  @optional_callbacks handle: 2, handle_error: 1
end
