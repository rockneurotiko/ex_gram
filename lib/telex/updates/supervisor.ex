defmodule Telex.Updates.Supervisor do
  # No longer in use

  use Supervisor
  require Logger

  def start_link(pid) do
    Supervisor.start_link(__MODULE__, {:ok, pid})
  end

  def init({:ok, pid}) do
    children = [
      worker(Telex.Updates.Worker, [{:bot, pid}])
    ]

    Logger.debug "SUPERVISOR"

    # supervise/2 is imported from Supervisor.Spec
    supervise(children, strategy: :one_for_one)
  end
end
