defmodule ExGram.Updates.Test do
  @moduledoc """
  Updates implementation for testing purposes
  """

  use GenServer

  defstruct [:pid, :token]

  def start_link({:bot, pid, :token, token}) do
    GenServer.start_link(__MODULE__, {:ok, pid, token})
  end

  def init({:ok, pid, token}) do
    {:ok, %__MODULE__{pid: pid, token: token}}
  end
end
