defmodule ExGram.Updates.Test do
  @moduledoc """
  Updates implementation for testing purposes.

  This GenServer implements the updates interface for test environments. Instead of
  fetching updates from Telegram, it allows pushing updates synchronously via
  `push_update/2`.

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
    {:ok, %__MODULE__{pid: pid, token: token}}
  end

  @doc """
  Push an update synchronously through the bot's `ExGram.Dispatcher` pipeline.

  Automatically allows the Dispatcher process to use the caller's test adapter stubs
  via [NimbleOwnership](https://hexdocs.pm/nimble_ownership).

  ## Parameters

    * `bot_name` - The bot's registered name (atom), which is also the Dispatcher's name
    * `update` - An `t:ExGram.Model.Update.t/0` struct

  ## Example

      update = %ExGram.Model.Update{
        update_id: 1,
        message: %ExGram.Model.Message{...}
      }

      ExGram.Updates.Test.push_update(:my_bot, update)
  """
  def push_update(bot_name, %ExGram.Model.Update{} = update) do
    # Allow the Dispatcher process to access caller's adapter stubs.
    # The Dispatcher is registered under bot_name.
    # With {:sync_update}, the handler runs inside the Dispatcher process,
    # so it needs access to the test process's adapter stubs.
    if pid = Process.whereis(bot_name) do
      ExGram.Adapter.Test.allow(self(), pid)
    end

    GenServer.call(bot_name, {:sync_update, update})
  end
end
