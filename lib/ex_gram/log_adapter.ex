defmodule ExGram.LogAdapter do
  @moduledoc """
  Behaviour for loggers
  """

  @callback debug(String.t()) :: :ok
  @callback warn(String.t()) :: :ok
  @callback error(String.t()) :: :ok

  defmacro __using__(_options) do
    quote do
      require Logger

      alias unquote(ExGram.Config.get(:ex_gram, :log_adapter, Logger)), as: Logger
    end
  end
end
