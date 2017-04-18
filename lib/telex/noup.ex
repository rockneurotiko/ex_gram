defmodule Telex.Noup do
  use GenServer
  require Logger

  def start_link({:bot, pid, :token, token}) do
    Logger.debug "Start NO Updates worker"
    GenServer.start_link(__MODULE__, {:ok, pid, token}) # TODO: Use name
  end

  def init({:ok, pid, token}) do
    {:ok, {pid, token}}
  end
end
