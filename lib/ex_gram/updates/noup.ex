defmodule ExGram.Updates.Noup do
  @moduledoc """
  Updates implementation that just start a process but don't do anything
  """

  use GenServer

  require Logger

  def start_link(%{bot: pid, token: token}) do
    Logger.debug("Start NO Updates worker")
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    Process.flag(:trap_exit, true)
    start_time = ExGram.Telemetry.start([:updates, :init], %{bot: pid, method: :noup})
    ExGram.Telemetry.stop([:updates, :init], start_time, %{bot: pid, method: :noup})
    {:ok, {pid, token}}
  end

  def terminate(_reason, {pid, _token}) do
    ExGram.Telemetry.emit([:updates, :shutdown], %{bot: pid, method: :noup})
  end
end
