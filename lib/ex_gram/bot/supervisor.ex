defmodule ExGram.Bot.Supervisor do
  @moduledoc """
  Bot supervisor that starts the dispatcher and updates processes and tie them together
  """
  alias ExGram.Dispatcher

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
    supervisor_name = Module.concat(module, Supervisor)
    params = Keyword.merge(opts, name: name, module: module)
    Supervisor.start_link(ExGram.Bot.Supervisor, params, name: supervisor_name)
  end

  def init(opts) do
    updates_method = Keyword.fetch!(opts, :method)
    token = Keyword.fetch!(opts, :token)
    name = Keyword.fetch!(opts, :name)
    module = Keyword.fetch!(opts, :module)

    {:ok, _} = Registry.register(Registry.ExGram, name, token)

    updates_worker =
      case updates_method do
        :webhook ->
          ExGram.Updates.Webhook

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

    module.init(bot: name, token: token)
    if opts[:setup_commands], do: setup_commands(module.commands(), token)

    bot_info = get_bot_info(opts[:username], token)
    dispatcher_opts = Dispatcher.init_state(name, bot_info, module)

    children = [
      {Dispatcher, dispatcher_opts},
      {updates_worker, {:bot, name, :token, token}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_bot_info(username, _token) when is_binary(username),
    do: %ExGram.Model.User{username: username, is_bot: true}

  defp get_bot_info(_username, token) do
    case ExGram.get_me(token: token) do
      {:ok, bot} -> bot
      _ -> nil
    end
  end

  defp setup_commands(commands, token) do
    send_commands =
      for command <- commands, command[:description] != nil do
        %ExGram.Model.BotCommand{
          command: command[:command],
          description: command[:description]
        }
      end

    ExGram.set_my_commands(send_commands, token: token)
  end
end
