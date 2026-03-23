defmodule ExGram.BotInit.SetupCommands do
  @moduledoc """
  A `ExGram.BotInit` hook that registers the bot's commands with Telegram at
  startup.

  This hook is automatically injected by the dispatcher when
  `setup_commands: true` is given to `use ExGram.Bot` or when starting the
  bot:

      {MyBot, [method: :polling, token: token, setup_commands: true]}

  It delegates to `ExGram.Bot.SetupCommands.setup/2`, which calls
  `setMyCommands` for each declared command scope/language combination.

  The hook expects a `bot_module` key in the hook opts, which the dispatcher
  injects automatically. It reads `bot_module.commands()` to get the full
  command definitions.
  """

  @behaviour ExGram.BotInit

  @impl ExGram.BotInit
  def on_bot_init(opts) do
    bot_module = Keyword.fetch!(opts, :bot_module)
    ExGram.Bot.SetupCommands.setup(bot_module.commands(), opts[:token])
    :ok
  end
end
