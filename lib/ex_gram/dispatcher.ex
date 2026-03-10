defmodule ExGram.Dispatcher do
  @moduledoc """
  Named GenServer process that receives updates, applies middlewares for the bot,
  and calls the bot's `c:ExGram.Handler.handle/2` callback.

  This module is started automatically by the bot's supervisor and shouldn't be
  interacted with directly in most cases.
  """

  use GenServer

  alias ExGram.Bot
  alias ExGram.Cnt
  alias ExGram.Model

  @type init_opts() :: [username: String.t() | nil, setup_commands: boolean()]
  @type custom_key() :: any()

  @type parsed_message() ::
          {:command, key :: String.t() | custom_key(), Model.Message.t()}
          | {:text, String.t(), Model.Message.t()}
          | {:regex, key :: custom_key(), Model.Message.t()}
          | {:location, Model.Location.t()}
          | {:message, Model.Message.t()}
          | {:callback_query, Model.CallbackQuery.t()}
          | {:inline_query, Model.InlineQuery.t()}
          | {:edited_message, Model.Message.t()}
          | {:pinned_message, Model.Message.t()}
          | {:update, Model.Update.t()}

  @type t() :: %__MODULE__{
          name: atom(),
          bot_info: Model.User.t() | nil,
          dispatcher_name: atom(),
          extra_info: map(),
          init_opts: init_opts(),
          commands: %{String.t() => map()},
          regex: [Regex.t()],
          middlewares: [Bot.middleware()],
          handler: {module(), atom()},
          error_handler: {module(), atom()}
        }

  defstruct name: __MODULE__,
            bot_info: nil,
            bot_module: nil,
            dispatcher_name: __MODULE__,
            extra_info: %{},
            init_opts: [username: nil, setup_commands: false],
            commands: %{},
            regex: [],
            middlewares: [],
            handler: nil,
            error_handler: nil

  @doc """
  Create a new Dispatcher struct, applying the given overrides to the default fields.
  
  ## Parameters
  
    - overrides: an enumerable (typically a map) with keys and values to override in the returned %ExGram.Dispatcher{} struct.
  
  ## Returns
  
  The constructed %ExGram.Dispatcher{} with defaults merged with `overrides`.
  """
  @spec new(Enumerable.t()) :: t()
  def new(overrides \\ %{}) do
    struct!(__MODULE__, overrides)
  end

  @doc """
  Constructs the initial Dispatcher state for a bot.
  
  Creates a %ExGram.Dispatcher{} populated from the provided name, bot module, init options, and extra info. If `opts[:username]` is present, `bot_info` is initialized to a bot user with that username. The returned state contains prepared commands, configured regexes and middlewares from the module, and default handler/error_handler pairs pointing to the module's `:handle` and `:handle_error` functions.
  
  ## Parameters
  
    - name: Registered name (atom) for the dispatcher.
    - module: Bot module implementing command/regex/middleware callbacks.
    - opts: Initialization options; recognized keys include:
      - `:username` — when present, used to seed `bot_info` as a bot user.
      - `:setup_commands` — stored in the state for later initialization steps.
    - extra_info: Arbitrary map stored on the dispatcher state.
  
  ## Returns
  
    - A fully populated `t()` dispatcher struct ready for GenServer initialization.
  """
  @spec init_state(atom(), module(), init_opts(), map()) :: t()
  def init_state(name, module, opts, extra_info) when is_atom(name) and is_atom(module) do
    bot_info = if username = opts[:username], do: %Model.User{username: username, is_bot: true}

    %__MODULE__{
      name: name,
      bot_info: bot_info,
      bot_module: module,
      dispatcher_name: name,
      extra_info: extra_info,
      init_opts: opts,
      commands: prepare_commands(module.commands()),
      regex: module.regexes(),
      middlewares: module.middlewares(),
      handler: {module, :handle},
      error_handler: {module, :handle_error}
    }
  end

  @spec prepare_commands([Keyword.t()]) :: %{String.t() => map()}
  defp prepare_commands(commands) when is_list(commands) do
    commands
    |> Enum.flat_map(fn command ->
      command_map = Map.new(command)
      base_entry = {command_map.command, command_map}

      # Add lang command variations
      lang_entries =
        for {_lang_code, overrides} <- command_map[:lang] || [],
            lang_command = overrides[:command],
            lang_command != nil do
          {lang_command, command_map}
        end

      [base_entry | lang_entries]
    end)
    |> Map.new()
  end

  @spec start_link(t()) :: GenServer.on_start()
  def start_link(%__MODULE__{dispatcher_name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl GenServer
  @doc """
  Initializes the dispatcher GenServer state and requests a continuation to perform bot initialization.
  
  Returns the given dispatcher state and signals a `:continue` with `:initialize_bot` so initialization that requires external resources (token fetch, bot setup) runs in handle_continue/2.
  """
  @spec init(t()) :: {:ok, t(), {:continue, :initialize_bot}}
  def init(%__MODULE__{} = state) do
    {:ok, state, {:continue, :initialize_bot}}
  end

  @impl GenServer
  @doc """
  Performs continuation-based initialization for the dispatcher: obtains the bot token, calls the bot module's `init/1`, resolves the bot's user info, optionally registers bot commands, and updates the dispatcher state with the retrieved bot info.
  """
  @spec handle_continue(:initialize_bot, t()) :: {:noreply, t()}
  def handle_continue(:initialize_bot, %__MODULE__{} = state) do
    token = ExGram.Token.fetch(bot: state.name)

    state.bot_module.init(bot: state.name, token: token, extra_info: state.extra_info)

    bot_info = get_bot_info(state, token)

    # We have to use bot_module.commands() to get the raw commands definitions
    if state.init_opts[:setup_commands], do: Bot.SetupCommands.setup(state.bot_module.commands(), token)

    {:noreply, %{state | bot_info: bot_info}}
  end

  defp get_bot_info(%__MODULE__{bot_info: %Model.User{} = bot_info}, _token), do: bot_info

  defp get_bot_info(%__MODULE__{}, token) do
    case ExGram.get_me(token: token) do
      {:ok, bot} -> bot
      _ -> nil
    end
  end

  @impl GenServer
  @doc """
  Handles an `{:update, update}` GenServer call by building a dispatcher context, running the middleware pipeline, and—if the context is not halted—extracting the parsed info and invoking the bot handler asynchronously.
  
  The function always replies `:ok` to the caller and leaves the dispatcher state unchanged.
  """
  @spec handle_call({:update, any()}, GenServer.from(), t()) :: {:reply, :ok, t()}
  def handle_call({:update, update}, _from, %__MODULE__{} = state) do
    cnt = %{default_context(state) | update: update}
    cnt = apply_middlewares(cnt)

    if !(cnt.halted || cnt.middleware_halted) do
      info = extract_info(cnt)
      spawn(fn -> call_handler(info, cnt, state) end)
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  @doc """
  Processes a raw update synchronously: runs it through the middleware pipeline and, unless halted, extracts parsed information and invokes the bot handler.
  
  The GenServer call always replies `:ok`.
  """
  @spec handle_call({:sync_update, any()}, GenServer.from(), t()) :: {:reply, :ok, t()}
  def handle_call({:sync_update, update}, _from, %__MODULE__{} = state) do
    cnt = %{default_context(state) | update: update}
    cnt = apply_middlewares(cnt)

    if !(cnt.halted || cnt.middleware_halted) do
      info = extract_info(cnt)
      call_handler(info, cnt, state)
    end

    {:reply, :ok, state}
  end

  @doc """
  Handles a synchronous GenServer call containing a bot-originated message: builds a dispatcher context, runs middlewares, and either returns `:halted` if processing was stopped or forwards the message to the bot handler and returns its response.
  """
  @spec handle_call({:message, term(), term()}, term(), t()) :: {:reply, term(), t()}
  def handle_call({:message, origin, msg}, from, %__MODULE__{} = state) do
    bot_message = {:bot_message, origin, msg}

    cnt = build_context_with_middlewares(state, bot_message, %{from: from})

    if cnt.halted do
      {:reply, :halted, state}
    else
      response = call_handler(bot_message, cnt, state)
      {:reply, response, state}
    end
  end

  def handle_call(msg, from, %__MODULE__{} = state) do
    message = {:call, msg}

    cnt = build_context_with_middlewares(state, message, %{from: from})

    if cnt.halted do
      {:reply, :halted, state}
    else
      response = call_handler(message, cnt, state)
      {:reply, response, state}
    end
  end

  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  @impl GenServer
  def handle_cast(msg, %__MODULE__{} = state) do
    message = {:cast, msg}
    cnt = build_context_with_middlewares(state, message)

    if !cnt.halted do
      spawn(fn -> call_handler(message, cnt, state) end)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, %__MODULE__{} = state) do
    message = {:info, msg}
    cnt = %{default_context(state) | message: message}
    cnt = apply_middlewares(cnt)

    if !cnt.halted do
      call_handler(message, cnt, state)
    end

    {:noreply, state}
  end

  @spec default_context(t()) :: Cnt.t()
  defp default_context(%__MODULE__{
         name: name,
         bot_info: bot_info,
         extra_info: extra_info,
         middlewares: middlewares,
         commands: commands,
         regex: regex
       }) do
    %Cnt{
      name: name,
      bot_info: bot_info,
      halted: false,
      middlewares: middlewares,
      commands: commands,
      regex: regex,
      extra: extra_info
    }
  end

  defp build_context_with_middlewares(state, message, extra \\ %{}) do
    %{default_context(state) | message: message}
    |> ExGram.Middleware.add_extra(extra)
    |> apply_middlewares()
  end

  @spec handle_text(String.t(), Cnt.t()) ::
          {:command, key :: String.t() | custom_key(), text :: String.t()}
          | {:text, String.t()}
          | {:regex, key :: custom_key(), text :: String.t()}
  defp handle_text("/" <> text, %Cnt{commands: commands}) do
    {cmd, text} =
      case String.split(text, ~r/\s/, parts: 2) do
        [cmd] -> {cmd, ""}
        [cmd, rest] -> {cmd, rest}
      end

    case Map.get(commands, cmd) do
      %{name: name} -> {:command, name, text}
      nil -> {:command, cmd, text}
    end
  end

  defp handle_text(text, %Cnt{regex: []}) do
    {:text, text}
  end

  defp handle_text(text, %Cnt{regex: regex}) do
    case Enum.find(regex, &Regex.match?(Keyword.get(&1, :regex), text)) do
      nil -> {:text, text}
      reg -> {:regex, Keyword.get(reg, :name), text}
    end
  end

  defp handle_message_text(text, message, field, cnt) do
    case handle_text(text, cnt) do
      {:command, key, rest} -> {:command, key, %{message | field => rest}}
      {:text, _rest} -> {:text, text, message}
      {:regex, key, _rest} -> {:regex, key, message}
    end
  end

  @spec extract_info(Cnt.t()) :: parsed_message()
  defp extract_info(%Cnt{update: %{message: %{text: text} = message}} = cnt) when is_binary(text) do
    handle_message_text(text, message, :text, cnt)
  end

  defp extract_info(%Cnt{update: %{message: %{caption: text} = message}} = cnt) when is_binary(text) do
    handle_message_text(text, message, :caption, cnt)
  end

  defp extract_info(%Cnt{update: %{message: %{location: %{} = location}}}) do
    {:location, location}
  end

  defp extract_info(%Cnt{update: %{message: %{pinned_message: %{} = message}}}) do
    {:pinned_message, message}
  end

  defp extract_info(%Cnt{update: %{message: %{} = message}}) do
    {:message, message}
  end

  defp extract_info(%Cnt{update: %{callback_query: %{} = callback_query}}) do
    {:callback_query, callback_query}
  end

  defp extract_info(%Cnt{update: %{inline_query: %{} = inline_query}}) do
    {:inline_query, inline_query}
  end

  defp extract_info(%Cnt{update: %{edited_message: %{} = edited_message}}) do
    {:edited_message, edited_message}
  end

  # channel_post
  # edited_channel_post
  # chosen_inline_result
  # shipping_query
  # pre_checkout_query
  defp extract_info(%Cnt{update: update}) do
    {:update, update}
  end

  defp apply_middlewares(%Cnt{middlewares: []} = cnt), do: cnt
  defp apply_middlewares(%Cnt{halted: true} = cnt), do: cnt
  defp apply_middlewares(%Cnt{middleware_halted: true} = cnt), do: cnt

  defp apply_middlewares(%Cnt{middlewares: [{fun, opts} | rest]} = cnt) when is_function(fun, 2) do
    %{cnt | middlewares: rest}
    |> fun.(opts)
    |> apply_middlewares()
  end

  defp apply_middlewares(%Cnt{middlewares: [{module, opts} | rest]} = cnt) when is_atom(module) do
    init_opts = module.init(opts)

    %{cnt | middlewares: rest}
    |> module.call(init_opts)
    |> apply_middlewares()
  end

  defp apply_middlewares(%Cnt{middlewares: [_ | rest]} = cnt) do
    apply_middlewares(%{cnt | middlewares: rest})
  end

  defp call_handler(info, cnt, %__MODULE__{handler: {module, method}} = state) do
    case apply(module, method, [info, cnt]) do
      %Cnt{} = cnt ->
        %Cnt{responses: responses} = ExGram.Dsl.send_answers(cnt)
        handle_responses(responses, state)

      _ ->
        :noop
    end
  end

  defp handle_responses([], _state), do: []

  defp handle_responses([{:error, error} | rest], %{error_handler: {module, method}} = state) do
    apply(module, method, [error])
    handle_responses(rest, state)
  end

  defp handle_responses([value | rest], state) do
    [value | handle_responses(rest, state)]
  end
end
