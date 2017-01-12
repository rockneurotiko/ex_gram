defmodule Telex.Bot do
  defmacro __using__(_) do
    quote do
      use GenServer

      import Telex.Commands

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      def start_link(:webhook) do
        raise "Not implemented yet"
      end

      def start_link(t) do
        IO.puts "Start bot"
        {:ok, pid} = GenServer.start_link(__MODULE__, {:ok, :updates})

        IO.puts "Start updates"
        # who supervises this supervisor? xD
        {:ok, _} = Telex.Updates.Supervisor.start_link(pid)
        IO.puts "END"
        # send
        {:ok, pid}
      end

      def init({:ok, t}) do
        {:ok, [type: t]}
      end

      def handle_call({:update, u}, _from, s) do
        IO.inspect u
        IO.inspect s
        {:reply, :ok, s}
      end
    end
  end
end
