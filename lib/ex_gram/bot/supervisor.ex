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
    supervisor_name = opts[:name] || Module.concat(module, Supervisor)
    params = Keyword.put(opts, :module, module)
    Supervisor.start_link(ExGram.Bot.Supervisor, params, name: supervisor_name)
  end

  def init(opts) do
    updates_method = Keyword.fetch!(opts, :method)
    token = Keyword.fetch!(opts, :token)
    module = Keyword.fetch!(opts, :module)
    name = Keyword.get(opts, :bot_name, module.name())

    {:ok, _} = Registry.register(Registry.ExGram, name, token)

    {updates_worker, updates_worker_opts} = updates_worker(updates_method)
    updates_worker_opts = Map.merge(updates_worker_opts, %{bot: name, token: token})

    if opts[:setup_commands], do: setup_commands(module.commands(), token)

    bot_info = get_bot_info(opts[:username], token)
    extra_info = Keyword.get(opts, :extra_info, %{})
    dispatcher_opts = Dispatcher.init_state(name, bot_info, module, extra_info)

    children =
      [
        {Dispatcher, dispatcher_opts},
        {updates_worker, updates_worker_opts}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp updates_worker(nil), do: raise("No updates method received, try with :polling or your custom module")

  defp updates_worker(name) when is_atom(name) do
    {updates_worker_module(name), %{}}
  end

  defp updates_worker({name, options}) when is_atom(name) do
    {updates_worker_module(name), Map.new(options)}
  end

  defp updates_worker_module(:webhook), do: ExGram.Updates.Webhook
  defp updates_worker_module(:noup), do: ExGram.Updates.Noup
  defp updates_worker_module(:polling), do: ExGram.Updates.Polling
  defp updates_worker_module(:test), do: ExGram.Updates.Test
  defp updates_worker_module(module) when is_atom(module), do: module

  defp get_bot_info(username, _token) when is_binary(username), do: %ExGram.Model.User{username: username, is_bot: true}

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
