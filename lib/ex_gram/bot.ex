defmodule ExGram.Bot do
  defmacro __using__(ops) do
    name =
      case Keyword.fetch(ops, :name) do
        {:ok, n} -> n
        _ -> raise "name parameter is mandatory"
      end

    username = Keyword.fetch(ops, :username)

    commands = quote do: commands()

    regexes = quote do: regexes()

    middlewares = quote do: middlewares()

    # quote location: :keep do
    quote do
      use Supervisor
      use ExGram.Middleware.Builder

      import ExGram.Dsl

      @behaviour ExGram.Handler

      def name(), do: unquote(name)

      def start_link(m, token \\ nil) do
        start_link(m, token, unquote(name))
      end

      defp start_link(m, token, name) do
        Supervisor.start_link(__MODULE__, {:ok, m, token, name}, name: name)
      end

      def init({:ok, updates_method, token, name}) do
        {:ok, _} = Registry.register(Registry.ExGram, name, token)

        updates_worker =
          case updates_method do
            :webhook ->
              raise "Not implemented yet"

            :noup ->
              ExGram.Updates.Noup

            :polling ->
              ExGram.Updates.Polling

            :test ->
              ExGram.Updates.Test

            other ->
              other
          end

        bot_info = maybe_fetch_bot(unquote(username), token)

        dispatcher_name = String.to_atom(Atom.to_string(name) <> "_dispatcher")

        dispatcher_opts = %ExGram.Dispatcher{
          name: name,
          bot_info: bot_info,
          dispatcher_name: dispatcher_name,
          commands: unquote(commands),
          regex: unquote(regexes),
          middlewares: unquote(middlewares),
          handler: &do_handle/2,
          error_handler: &do_handle_error/1
        }

        children = [
          worker(ExGram.Dispatcher, [dispatcher_opts]),
          worker(updates_worker, [{:bot, dispatcher_name, :token, token}])
        ]

        supervise(children, strategy: :one_for_one)
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
        IO.inspect("Error received: #{inspect(error)}")
      end

      defoverridable ExGram.Handler

      defp do_handle(msg, cnt), do: __MODULE__.handle(msg, cnt)
      defp do_handle_error(error), do: __MODULE__.handle_error(error)

      defp maybe_fetch_bot(username, _token) when is_binary(username),
        do: %ExGram.Model.User{username: username, is_bot: true}

      defp maybe_fetch_bot(_username, token) do
        with {:ok, bot} <- ExGram.get_me(token: token) do
          bot
        else
          _ -> nil
        end
      end
    end
  end
end
