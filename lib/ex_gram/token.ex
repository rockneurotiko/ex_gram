defmodule ExGram.Token do
  @moduledoc """
  Helpers when dealing with bot's tokens
  """

  require Logger

  @registry Registry.ExGram

  @doc """
  Main logic to extract the token of the bot.

  The options can have the following keys:
  - token: Explicit token to be used, this ignore everything else and will use this one
  - bot: Bot name to be used, the token will be retrieved from the registry
  - registry: Optional. Registry to extract the bot's token. By default will use ExGram.Registry.

  Usage:

  ExGram.Token.fetch() # Will take it from the config (config :ex_gram, token: "token")

  ExGram.Token.fetch(token: "MyToken") # Will use the token

  ExGram.Token.fetch(bot: :my_bot) # Will look in ExGram.Registry for :my_bot token

  ExGram.Token.fetch(bot: :my_bot, registry: OtherRegistry) # Will look in OtherRegistry for :My_bot token
  """
  @spec fetch(keyword) :: String.t() | nil
  def fetch(ops \\ []) when is_list(ops) do
    case {Keyword.get(ops, :token), Keyword.get(ops, :bot)} do
      {nil, nil} ->
        ExGram.Config.get(:ex_gram, :token)

      {token, nil} ->
        token

      {nil, bot} ->
        fetch_registry_token(bot, ops)
    end
  end

  defp fetch_registry_token(bot, ops) do
    registry = Keyword.get(ops, :registry, @registry)

    case Registry.lookup(registry, bot) do
      [{_, token} | _] when is_binary(token) ->
        token

      [{_, _other} | _] ->
        Logger.warn(error_msg(:no_token, bot))
        nil

      _ ->
        Logger.warn(error_msg(:no_bot, bot))
        nil
    end
  end

  defp error_msg(:no_token, bot) do
    ~s(The bot \"#{inspect(bot)}\" does not have a token specified. Did you started the bot with the token?
      children = [
        # ...
        ExGram,
        {MyBot, [method: :polling, token: token]}
      ]
    )
  end

  defp error_msg(:no_bot, bot) do
    ~s(The bot \"#{inspect(bot)}\" is not registered. Make sure that this bot exists and is started.)
  end
end
