defmodule Telex.Bot do
  defmacro __using__([name: name]) do
    quote do
      use Supervisor

      require Logger

      Module.register_attribute(__MODULE__, :dispatchers, accumulate: true)
      # Module.register_attribute(__MODULE__, :commands, accumulate: true)
      # Module.register_attribute(__MODULE__, :edited_msg, accumulate: true)
      # Module.register_attribute(__MODULE__, :channel_post, accumulate: true)
      # Module.register_attribute(__MODULE__, :channel_edited_post, accumulate: true)
      # Module.register_attribute(__MODULE__, :inline_query, accumulate: true)
      # Module.register_attribute(__MODULE__, :chosen_inline_result, accumulate: true)
      # Module.register_attribute(__MODULE__, :callback_query, accumulate: true)

      def start_link(t, token \\ nil) do
        start_link(t, token, unquote(name))
      end

      def start_link(:webhook, _token, _name) do
        raise "Not implemented yet"
      end

      def start_link(_t, token, name) do
        Supervisor.start_link(__MODULE__, {:ok, token, name})
      end

      def init({:ok, token, name}) do
        {:ok, _} = Registry.register(Registry.Telex, name, token)

        children = [
          worker(Telex.Dispatcher, [[name: name,
                                     dispatchers: dispatchers()
                                     # commands: commands(),
                                     # edited_msg: edited_msg(),
                                     # channel_post: channel_post(),
                                     # channel_edited_post: channel_edited_post(),
                                     # inline_query: inline_query(),
                                     # chosen_inline_result: chosen_inline_result(),
                                     # callback_query: callback_query()
                                    ]]),
          worker(Telex.Updates.Worker, [{:bot, name, :token, token}])
        ]

        Logger.info "Starting bot!"

        supervise(children, strategy: :one_for_one)
      end

      @before_compile Telex.Bot
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp dispatchers, do: @dispatchers
      # defp commands, do: @commands
      # defp edited_msg, do: @edited_msg
      # defp channel_post, do: @channel_post
      # defp channel_edited_post, do: @channel_edited_post
      # defp inline_query, do: @inline_query
      # defp chosen_inline_result, do: @chosen_inline_result
      # defp callback_query, do: @callback_query
    end
  end
end
