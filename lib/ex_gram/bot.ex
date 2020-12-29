defmodule ExGram.Bot do
  defmacro __using__(ops) do
    name =
      case Keyword.fetch(ops, :name) do
        {:ok, n} -> n
        _ -> raise "name parameter is mandatory"
      end

    username = Keyword.fetch(ops, :username)
    setup_commands = Keyword.get(ops, :setup_commands, false)

    quote location: :keep do
      # quote do
      use ExGram.Middleware.Builder

      import ExGram.Dsl

      @behaviour ExGram.Handler

      def name(), do: unquote(name)

      def child_spec(opts) do
        opts =
          Keyword.merge(opts, setup_commands: unquote(setup_commands), username: unquote(username))

        ExGram.Bot.Supervisor.child_spec(opts, __MODULE__)
      end

      @dialyzer {:nowarn_function, start_link: 1}
      def start_link(opts) when is_list(opts) do
        message = """
        Outdate child specification, change your bot's children config to the following:
        {#{__MODULE__}, #{inspect(opts)}}
        """

        raise message
      end

      def start_link(m, token \\ nil) do
        message = """
        Outdate child specification, change your bot's children config to the following:
        {#{__MODULE__}, [method: #{m}, token: #{token}]}
        """

        raise message
      end

      def message(from, message) do
        GenServer.call(name(), {:message, from, message})
      end

      # Default implementations
      def handle(msg, _cnt) do
        error = %ExGram.Error{code: :not_handled, message: "Message not handled: #{inspect(msg)}"}
        handle_error(error)
      end

      def handle_error(error) do
        error
        # IO.inspect("Error received: #{inspect(error)}")
      end

      defoverridable ExGram.Handler
    end
  end
end
