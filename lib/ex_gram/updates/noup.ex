defmodule ExGram.Updates.Noup do
  @moduledoc """
  Updates implementation that just start a process but don't do anything
  """

  use GenServer

  require Logger

  def start_link(%{bot: bot, token: token}) do
    Logger.debug("Start NO Updates worker")
    GenServer.start_link(__MODULE__, {:ok, bot, token})
  end

  def init({:ok, bot, token}) do
    Process.flag(:trap_exit, true)
    start_time = ExGram.Telemetry.start([:updates, :init], %{bot: bot, method: :noup})
    ExGram.Telemetry.stop([:updates, :init], start_time, %{bot: bot, method: :noup})
    {:ok, {bot, token}}
  end

  def terminate(_reason, {bot, _token}) do
    ExGram.Telemetry.emit([:updates, :shutdown], %{bot: bot, method: :noup})
  end
end
