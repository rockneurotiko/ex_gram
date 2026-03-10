defmodule ExGram.Bot.Supervisor do
  @moduledoc """
  Bot supervisor that starts the `ExGram.Dispatcher` and Updates processes.

  This supervisor coordinates the lifecycle of a bot's core components: the dispatcher
  (which handles incoming updates) and the updates worker (which fetches or receives
  updates from Telegram via polling, webhooks, or test mode).

  See the [Polling and Webhooks guide](polling-and-webhooks.md) for more details about different updates methods and the [testing guide](testing.md) for using the test updates worker in your tests.
  """
  alias ExGram.Dispatcher

  @doc """
  Builds a supervision child specification for the given bot module using the provided options.
  
  The resulting map includes:
    - :id — `opts[:id]` or the `module` when no id is provided.
    - :start — `{ExGram.Bot.Supervisor, :start_link, [opts, module]}`.
    - :type — `:supervisor`.
    - :restart — `:permanent`.
    - :shutdown — `500` (milliseconds).
  """
  @spec child_spec(Keyword.t(), module()) :: map()
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

  @doc """
  Initializes the bot supervisor by registering the bot, preparing the Dispatcher and updates worker child specifications, and starting a one_for_one supervision tree.
  
  Required options in `opts`:
    - `:method` - updates method identifier or module (required)
    - `:token` - bot token (required)
    - `:module` - bot module implementing handlers (required)
  
  Optional keys read from `opts`:
    - `:bot_name` - overrides the bot name (defaults to `module.name()`)
    - `:extra_info` - map merged into dispatcher state
    - `:username`, `:setup_commands` - passed to the dispatcher via init options
  
  @spec init(keyword()) :: {:ok, term()}
  @throws KeyError if `:method`, `:token`, or `:module` are not present in `opts`.
  """
  def init(opts) do
    updates_method = Keyword.fetch!(opts, :method)
    token = Keyword.fetch!(opts, :token)
    module = Keyword.fetch!(opts, :module)
    name = Keyword.get(opts, :bot_name, module.name())

    {:ok, _} = Registry.register(Registry.ExGram, name, token)

    {updates_worker, updates_worker_opts} = updates_worker(updates_method)
    updates_worker_opts = Map.merge(updates_worker_opts, %{bot: name, token: token})

    extra_info = Keyword.get(opts, :extra_info, %{})
    dispatcher_init_opts = Keyword.take(opts, [:username, :setup_commands])
    dispatcher_opts = Dispatcher.init_state(name, module, dispatcher_init_opts, extra_info)

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
end
