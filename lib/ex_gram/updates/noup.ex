defmodule ExGram.Updates.Noup do
  @moduledoc """
  Updates implementation that just start a process but don't do anything
  """

  use GenServer
  require Logger

  def start_link({:bot, pid, :token, token}) do
    Logger.debug("Start NO Updates worker")
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    {:ok, {pid, token}}
  end
end
