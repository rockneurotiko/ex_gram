defmodule ExGram.Dispatcher do
  @moduledoc """
  Named process that receive the updates, apply the middlewares for the bot and call the bot's handler
  """

  use GenServer

  alias ExGram.Bot
  alias ExGram.Cnt
  alias ExGram.Model

  @type t :: %__MODULE__{
          name: atom,
          bot_info: Model.User.t() | nil,
          dispatcher_name: atom(),
          commands: %{String.t() => map()},
          regex: list(),
          middlewares: [Bot.middleware()],
          handler: {module(), atom()},
          error_handler: {module(), atom()}
        }

  defstruct name: __MODULE__,
            bot_info: nil,
            dispatcher_name: __MODULE__,
            commands: %{},
            regex: [],
            middlewares: [],
            handler: nil,
            error_handler: nil

  def new(overrides \\ %{}) do
    struct!(__MODULE__, overrides)
  end

  def init_state(name, %Model.User{} = bot_info, module)
      when is_atom(name) and is_atom(module) do
    %__MODULE__{
      name: name,
      bot_info: bot_info,
      dispatcher_name: name,
      commands: prepare_commands(module.commands()),
      regex: module.regexes(),
      middlewares: module.middlewares(),
      handler: {module, :handle},
      error_handler: {module, :handle_error}
    }
  end

  defp prepare_commands(commands) when is_list(commands) do
    Map.new(commands, fn command ->
      command = Map.new(command)
      {command.command, command}
    end)
  end

  def start_link(%__MODULE__{dispatcher_name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl GenServer
  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        {:update, update},
        _from,
        %{handler: handler, error_handler: error_handler} = state
      ) do
    cnt = %Cnt{default_context(state) | update: update}
    cnt = apply_middlewares(cnt)

    if not cnt.halted do
      info = extract_info(cnt)
      spawn(fn -> call_handler(handler, info, cnt, error_handler) end)
    end

    {:reply, :ok, state}
  end

  def handle_call({:update, _update}, _from, state) do
    {:reply, :error, state}
  end

  def handle_call(
        {:message, origin, msg},
        from,
        %{handler: handler, error_handler: error_handler} = state
      ) do
    bot_message = {:bot_message, origin, msg}
    cnt = %Cnt{default_context(state) | message: bot_message, extra: %{from: from}}
    cnt = apply_middlewares(cnt)

    if not cnt.halted do
      response = call_handler(handler, bot_message, cnt, error_handler)
      {:reply, response, state}
    else
      {:reply, :halted, state}
    end
  end

  def handle_call(msg, from, %{handler: handler, error_handler: error_handler} = state) do
    message = {:call, msg}
    cnt = %Cnt{default_context(state) | message: message, extra: %{from: from}}
    cnt = apply_middlewares(cnt)

    if not cnt.halted do
      response = call_handler(handler, message, cnt, error_handler)
      {:reply, response, state}
    else
      {:reply, :halted, state}
    end
  end

  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  @impl GenServer
  def handle_cast(msg, %{handler: handler, error_handler: error_handler} = state) do
    message = {:cast, msg}
    cnt = %Cnt{default_context(state) | message: message}
    cnt = apply_middlewares(cnt)

    if not cnt.halted do
      spawn(fn -> call_handler(handler, message, cnt, error_handler) end)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, %{handler: handler, error_handler: error_handler} = state) do
    message = {:info, msg}
    cnt = %Cnt{default_context(state) | message: message}
    cnt = apply_middlewares(cnt)

    if not cnt.halted do
      call_handler(handler, message, cnt, error_handler)
    end

    {:noreply, state}
  end

  defp default_context(%__MODULE__{
         name: name,
         bot_info: bot_info,
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
      regex: regex
    }
  end

  defp handle_text("/" <> text, %Cnt{commands: commands}) do
    {cmd, text} =
      case String.split(text, " ", parts: 2) do
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

  defp extract_info(%Cnt{update: %{message: %{text: text} = message}} = cnt)
       when is_binary(text) do
    case handle_text(text, cnt) do
      {:command, key, text} -> {:command, key, %{message | text: text}}
      {:text, text} -> {:text, text, %{message | text: text}}
      {:regex, key, text} -> {:regex, key, %{message | text: text}}
    end
  end

  defp extract_info(%Cnt{update: %{message: %{location: %{} = location}}}) do
    {:location, location}
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

  defp apply_middlewares(%Cnt{middlewares: [{fun, opts} | rest]} = cnt)
       when is_function(fun, 2) do
    %Cnt{cnt | middlewares: rest}
    |> fun.(opts)
    |> apply_middlewares()
  end

  defp apply_middlewares(%Cnt{middlewares: [{module, opts} | rest]} = cnt) when is_atom(module) do
    init_opts = module.init(opts)

    %Cnt{cnt | middlewares: rest}
    |> module.call(init_opts)
    |> apply_middlewares()
  end

  defp apply_middlewares(%Cnt{middlewares: [_ | rest]} = cnt) do
    apply_middlewares(%Cnt{cnt | middlewares: rest})
  end

  defp call_handler({module, method}, info, cnt, error_handler) do
    case apply(module, method, [info, cnt]) do
      %Cnt{} = cnt ->
        %Cnt{responses: responses} = ExGram.Dsl.send_answers(cnt)
        handle_responses(responses, error_handler)

      _ ->
        :noop
    end
  end

  defp handle_responses([], _error_handler), do: []

  defp handle_responses([{:error, error} | rest], {module, method} = error_handler) do
    apply(module, method, [error])
    handle_responses(rest, error_handler)
  end

  defp handle_responses([value | rest], error_handler) do
    [value | handle_responses(rest, error_handler)]
  end
end
