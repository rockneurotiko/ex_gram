defmodule Telex.Updates.Noup do
  use GenServer
  require Logger

  def start_link({:bot, pid, :token, token}) do
    Logger.debug("Start NO Updates worker")
    # TODO: Use name
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    {:ok, {pid, token}}
  end
end
