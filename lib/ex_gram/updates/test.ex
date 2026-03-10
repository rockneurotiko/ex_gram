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

  @doc """
  Builds a Supervisor child specification for ExGram.Updates.Test.
  
  The returned spec uses this module's start_link/1 as the start callback, sets the process type to `:worker`, restart strategy to `:permanent`, and a shutdown timeout of 500 ms. If `opts[:bot]` is present the child `:id` is Module.concat(__MODULE__, bot); otherwise the `:id` is this module.
  
  ## Parameters
  
    - opts: map of options passed to start_link/1. Recognized keys:
      - `:bot` — optional identifier used to derive a unique child id.
  
  """
  @spec child_spec(map()) :: Supervisor.child_spec()
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

  @doc """
  Starts the Test updates GenServer for the given bot.
  
  Accepts an options map that must include `:bot` (the bot process pid) and `:token`. If `:name` is present the GenServer is started and registered under that name; otherwise it is started unnamed.
  """
  @spec start_link(map()) :: GenServer.on_start()
  def start_link(%{bot: pid, token: token} = opts) do
    if name = opts[:name] do
      GenServer.start_link(__MODULE__, {:ok, pid, token}, name: name)
    else
      GenServer.start_link(__MODULE__, {:ok, pid, token})
    end
  end

  @doc """
  Initialize the GenServer state with the provided bot process pid and token.
  
  Constructs the module struct containing the bot `pid` and `token` and prepares it as the server state.
  """
  @spec init({:ok, pid(), any()}) :: {:ok, %__MODULE__{}}
  def init({:ok, pid, token}) do
    {:ok, %__MODULE__{pid: pid, token: token}}
  end

  @doc """
  Pushes an update through the bot's Dispatcher pipeline.
  
  If a Dispatcher is registered under `bot_name`, grants that process access to the caller's test adapter stubs (via NimbleOwnership) so the update is handled using test adapters before being dispatched.
  
  ## Parameters
  
    - bot_name: registered name (atom) of the bot/Dispatcher
    - update: an `ExGram.Model.Update` struct to deliver
  """
  @spec push_update(atom(), ExGram.Model.Update.t()) :: any()
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
