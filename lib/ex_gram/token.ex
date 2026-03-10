defmodule ExGram.Token do
  @moduledoc """
  Helpers for working with bot tokens.

  This module provides the `fetch/1` function to retrieve bot tokens from various
  sources: explicit options, the bot registry, or application configuration.

  See `ExGram.Bot` for how tokens are registered during bot startup.
  """

  require Logger

  @registry Registry.ExGram

  
  
  @doc """
  Retrieve a Telegram bot token from provided options, the registry, or application config.
  
  Options:
    * `:token` - explicit token to use (takes precedence)
    * `:bot` - atom name of a registered bot to lookup in a registry
    * `:registry` - optional registry to query (defaults to `Registry.ExGram`)
  
  Returns the first available token found from these sources in precedence order: explicit `:token`, registry lookup for `:bot`, then application config `:ex_gram` `:token`.
  
  ## Examples
  
      ExGram.Token.fetch() # From config :ex_gram, :token
  
      ExGram.Token.fetch(token: "MyToken") # Explicit token
  
      ExGram.Token.fetch(bot: :my_bot) # From Registry.ExGram
  
      ExGram.Token.fetch(bot: :my_bot, registry: OtherRegistry)
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
        Logger.warning(error_msg(:no_token, bot))
        nil

      _ ->
        Logger.warning(error_msg(:no_bot, bot))
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
