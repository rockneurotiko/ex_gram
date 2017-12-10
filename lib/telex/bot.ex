defmodule Telex.Bot do
  defmacro __using__(ops) do
    name =
      case Keyword.fetch(ops, :name) do
        {:ok, n} -> n
        _ -> raise "name parameter is mandatory"
      end

    commands =
      Keyword.get(ops, :commands, []) |> Enum.map(fn [command: _c, name: _n] = t -> t end)

    # Check commands are [command: "", name: ""]
    regexes =
      Keyword.get(ops, :regex, [])
      |> Enum.map(fn [regex: r, name: n] -> [regex: Regex.compile!(r), name: n] end)

    # Check regex are [regex: "", name: ""]

    middlewares = Keyword.get(ops, :middlewares, [])

    quote location: :keep do
      use Supervisor

      @behaviour Telex.Dsl.Handler

      defp name(), do: unquote(name)

      def start_link(t, token \\ nil) do
        start_link(t, token, unquote(name))
      end

      defp start_link(m, token, name) do
        # Use name too!
        Supervisor.start_link(__MODULE__, {:ok, m, token, name}, name: name)
      end

      def init({:ok, updates_method, token, name}) do
        {:ok, _} = Registry.register(Registry.Telex, name, token)

        updates_worker =
          case updates_method do
            :webhook ->
              raise "Not implemented yet"
              Telex.Webhook.Worker

            :noup ->
              Telex.Noup

            :polling ->
              Telex.Updates.Worker

            other ->
              other
          end

        dispatcher_name = String.to_atom(Atom.to_string(name) <> "_dispatcher")

        children = [
          worker(Telex.Dispatcher, [
            %{
              name: name,
              dispatcher_name: dispatcher_name,
              commands: unquote(commands),
              regex: unquote(regexes),
              middlewares: unquote(middlewares),
              handler: &handle/3
            }
          ]),
          worker(updates_worker, [{:bot, dispatcher_name, :token, token}])
        ]

        supervise(children, strategy: :one_for_one)
      end

      def message(from, message) do
        GenServer.call(name(), {:message, from, message})
      end
    end
  end
end
