defmodule ExGram.BotInit.GetMe do
  @moduledoc """
  A `ExGram.BotInit` hook that calls `ExGram.get_me/1` at bot startup to
  populate `bot_info` with the bot's `User` struct.

  This hook is automatically injected by the dispatcher when `get_me: true`
  (which is the default). Disable it with `get_me: false` when starting the
  bot:

      {MyBot, [method: :polling, token: token, get_me: false]}

  In tests, `ExGram.Test.start_bot/3` defaults to `get_me: false` to avoid
  making API calls.

  On success the hook returns `{:ok, %{bot_info: user}}`. The dispatcher
  extracts `bot_info` from `extra_info` after all hooks have run and stores it
  on the dispatcher state, so it never leaks into `Cnt.extra`.
  """

  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    case ExGram.get_me(token: opts[:token]) do
      {:ok, user} -> {:ok, %{bot_info: user}}
      {:error, error} -> {:error, {:get_me_failed, error}}
    end
  end
end
