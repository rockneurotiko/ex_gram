defmodule ExGram.Updates.Test do
  @moduledoc """
  Updates implementation for testing purposes.

  This GenServer implements the updates interface for test environments. Instead of
  fetching updates from Telegram, it provides `push_update/2` to inject updates
  directly into the bot's dispatcher.

  The actual synchrony of handler execution depends on the bot's `handler_mode`:

    * `:sync` (default when using `ExGram.Test.start_bot/3`) - the handler runs
      inline within the dispatcher's process; `push_update/2` blocks until it completes.
    * `:async` (production default) - the handler is spawned; `push_update/2` returns
      before the handler runs.

  Configured with `config :ex_gram, updates: ExGram.Updates.Test`.

  See the [Testing guide](testing.md) for more details.
  """

  use GenServer

  defstruct [:pid, :token]

  def child_spec(opts) do
    id =
      if bot = opts[:bot] do
        Module.concat(__MODULE__, bot)
      else
        __MODULE__
      end

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(%{bot: pid, token: token} = opts) do
    if name = opts[:name] do
      GenServer.start_link(__MODULE__, {:ok, pid, token}, name: name)
    else
      GenServer.start_link(__MODULE__, {:ok, pid, token})
    end
  end

  def init({:ok, pid, token}) do
    Process.flag(:trap_exit, true)
    start_time = ExGram.Telemetry.start([:updates, :init], %{bot: pid, method: :test})
    state = %__MODULE__{pid: pid, token: token}
    ExGram.Telemetry.stop([:updates, :init], start_time, %{bot: pid, method: :test})
    {:ok, state}
  end

  def terminate(_reason, %__MODULE__{pid: pid}) do
    ExGram.Telemetry.emit([:updates, :shutdown], %{bot: pid, method: :test})
  end

  @doc """
  Push an update through the bot's `ExGram.Dispatcher` pipeline.

  The update is delivered via `GenServer.call/2`, so the dispatcher always receives it
  synchronously. Whether this call blocks until the handler finishes depends on the
  bot's `handler_mode`:

    * `:sync` (default from `ExGram.Test.start_bot/3`) - the handler runs inline inside
      the dispatcher's `handle_call`, so this function returns only after the full
      pipeline has executed and all API calls have been made.
    * `:async` - the handler is spawned in a separate process; this function returns as
      soon as the dispatcher has enqueued the update.

  Process isolation is handled automatically by `ExGram.Test.start_bot/3`, which allows
  the Dispatcher and Updates worker to use the test's stubs from startup. No manual
  `allow/2` call is needed before calling this function.

  ## Parameters

    * `bot_name` - The bot's registered name (atom), which is also the Dispatcher's name
    * `update` - An `t:ExGram.Model.Update.t/0` struct

  ## Example

      update = %ExGram.Model.Update{
        update_id: 1,
        message: %ExGram.Model.Message{...}
      }

      # With handler_mode: :sync (default), the handler has completed when this returns
      ExGram.Updates.Test.push_update(:my_bot, update)
  """
  def push_update(bot_name, %ExGram.Model.Update{} = update) do
    GenServer.call(bot_name, {:update, update})
  end
end
