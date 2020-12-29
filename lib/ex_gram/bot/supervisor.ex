defmodule ExGram.Bot.Supervisor do
  @moduledoc """
  Bot supervisor that starts the dispatcher and updates processes and tie them together
  """

  def child_spec(opts, module) do
    %{
      id: opts[:id] || module,
      start: {ExGram.Bot.Supervisor, :start_link, [opts, module]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(opts, module) do
    name = opts[:name] || module.name()
    supervisor_name = String.to_atom(Atom.to_string(name) <> "_supervisor")
    params = Keyword.merge(opts, name: name, module: module)
    Supervisor.start_link(ExGram.Bot.Supervisor, params, name: supervisor_name)
  end

  def init(opts) do
    updates_method = Keyword.fetch!(opts, :method)
    token = Keyword.fetch!(opts, :token)
    name = Keyword.fetch!(opts, :name)
    module = opts[:module]
    commands = module.commands()

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

        nil ->
          raise "No updates method received, try with :polling or your custom module"

        other ->
          other
      end

    maybe_setup_commands(opts[:setup_commands], commands, token)

    bot_info = maybe_fetch_bot(opts[:username], token)

    dispatcher_opts = %ExGram.Dispatcher{
      name: name,
      bot_info: bot_info,
      dispatcher_name: name,
      commands: commands,
      regex: module.regexes(),
      middlewares: module.middlewares(),
      handler: {module, :handle},
      error_handler: {module, :handle_error}
    }

    children = [
      {ExGram.Dispatcher, dispatcher_opts},
      {updates_worker, {:bot, name, :token, token}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_fetch_bot(username, _token) when is_binary(username),
    do: %ExGram.Model.User{username: username, is_bot: true}

  defp maybe_fetch_bot(_username, token) do
    case ExGram.get_me(token: token) do
      {:ok, bot} -> bot
      _ -> nil
    end
  end

  defp maybe_setup_commands(true, commands, token) do
    send_commands =
      commands
      |> Stream.filter(fn command ->
        not is_nil(command[:description])
      end)
      |> Enum.map(fn command ->
        %ExGram.Model.BotCommand{
          command: command[:command],
          description: command[:description]
        }
      end)

    ExGram.set_my_commands(send_commands, token: token)
  end

  defp maybe_setup_commands(_, _commands, _token), do: :nop
end
