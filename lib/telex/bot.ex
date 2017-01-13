defmodule Telex.Bot do
  defmacro __using__(_) do
    quote do
      use GenServer

      import Telex.Commands
      require Logger

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      def start_link(:webhook) do
        raise "Not implemented yet"
      end

      def start_link(t) do
        Logger.debug "Start bot"
        {:ok, pid} = GenServer.start_link(__MODULE__, {:ok, :updates})

        Logger.debug "Start updates"
        # who supervises this supervisor? xD
        {:ok, _} = Telex.Updates.Supervisor.start_link(pid)
        Logger.debug "END"
        # send
        {:ok, pid}
      end

      def init({:ok, t}) do
        {:ok, [type: t]}
      end

      defp is_implemented?(handler, behaviour) do
        case handler.module_info[:attributes][:behaviour] do
          nil -> false
          ls -> Enum.any?(ls, fn l -> l == behaviour end)
        end
      end

      # Handle messages!
      defp handle_message(handler,  u) do
        if is_implemented?(handler, Telex.Dsl.Base) do
          if handler.test(u) do
            handler.execute(u)
          end
        end
      end

      # Message
      def handle_call({:update, %Telex.Model.Update{message: m} = u}, _f, s) when not is_nil(m) do
        Logger.debug("Handle message")
        commands() |> Enum.map(fn c -> handle_message(c, u) end)
        {:reply, :ok, s}
      end

      def handle_call({:update, u}, _from, s) do
        Logger.error "Update, not update? #{inspect(u)}"
        {:reply, :error, s}
      end

      @before_compile Telex.Bot
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp commands, do: @commands
    end
  end
end
