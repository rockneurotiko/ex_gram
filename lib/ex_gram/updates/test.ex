defmodule ExGram.Updates.Test do
  @moduledoc """
  Updates implementation for testing purposes
  """

  use GenServer

  defstruct [:pid, :token]

  def child_spec(opts) do
    %{
      id: __MODULE__,
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
  Push an update synchronously through the bot's Dispatcher pipeline.

  Automatically allows the Dispatcher process to use the caller's
  test adapter stubs via NimbleOwnership.

  ## Parameters

    - `bot_name`: The bot's registered name (atom), which is also the Dispatcher's name
    - `update`: An `%ExGram.Model.Update{}` struct

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
