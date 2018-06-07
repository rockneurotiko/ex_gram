defmodule ExGram.Dispatcher do
  use GenServer

  alias ExGram.Cnt

  @type t :: %__MODULE__{
          name: atom,
          bot_info: ExGram.Model.User.t() | nil,
          dispatcher_name: atom,
          commands: list(),
          regex: list(),
          middlewares: list(),
          handler: function,
          error_handler: function
        }

  defstruct [
    :name,
    :bot_info,
    :dispatcher_name,
    :commands,
    :regex,
    :middlewares,
    :handler,
    :error_handler
  ]

  def new(extra \\ %{}) do
    %__MODULE__{
      name: "",
      bot_info: nil,
      dispatcher_name: __MODULE__,
      commands: [],
      regex: [],
      middlewares: [],
      handler: fn _, _ -> :ok end,
      error_handler: fn _ -> :ok end
    }
    |> Map.merge(extra)
  end

  def start_link(%__MODULE__{dispatcher_name: name} = ops) do
    GenServer.start_link(__MODULE__, {:ok, ops}, name: name)
  end

  def init({:ok, ops}) do
    {:ok, ops}
  end

  def handle_call(
        {:update, u},
        _from,
        %{
          handler: handler,
          error_handler: error_handler
        } = s
      ) do
    cnt = create_cnt(s) |> Map.put(:update, u)

    case apply_middlewares(cnt) do
      %Cnt{halted: true} ->
        # Logger.info "Middleware cancel"
        true

      cnt ->
        info = extract_info(cnt)
        spawn(fn -> call_handler(handler, info, cnt, error_handler) end)
    end

    {:reply, :ok, s}
  end

  def handle_call({:update, _u}, _from, s) do
    # Logger.error "Update, not update? #{inspect(u)}\nState: #{inspect(s)}"
    {:reply, :error, s}
  end

  def handle_call(
        {:message, origin, msg},
        from,
        %{handler: handler, error_handler: error_handler} = s
      ) do
    bot_message = {:bot_message, origin, msg}
    cnt = create_cnt(s) |> Map.put(:message, bot_message) |> Map.put(:extra, %{from: from})

    case apply_middlewares(cnt) do
      %Cnt{halted: true} ->
        {:reply, :halted, s}

      cnt ->
        response = call_handler(handler, {:bot_message, origin, msg}, cnt, error_handler)
        {:reply, response, s}
    end
  end

  def handle_call(msg, from, %{handler: handler, error_handler: error_handler} = s) do
    cnt = create_cnt(s) |> Map.put(:message, {:call, msg}) |> Map.put(:extra, %{from: from})

    case apply_middlewares(cnt) do
      %Cnt{halted: true} ->
        {:reply, :halted, s}

      cnt ->
        response = call_handler(handler, {:call, msg}, cnt, error_handler)
        {:reply, response, s}
    end
  end

  def handle_cast(msg, %{handler: handler, error_handler: error_handler} = s) do
    cnt = create_cnt(s) |> Map.put(:message, {:cast, msg})

    case apply_middlewares(cnt) do
      %Cnt{halted: true} ->
        {:noreply, s}

      cnt ->
        spawn(fn -> call_handler(handler, {:cast, msg}, cnt, error_handler) end)
        {:noreply, s}
    end
  end

  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  defp create_cnt(%__MODULE__{
         name: name,
         bot_info: bot_info,
         middlewares: middlewares,
         commands: commands,
         regex: regex
       }) do
    Cnt.new(%{
      name: name,
      bot_info: bot_info,
      halted: false,
      middlewares: middlewares,
      commands: commands,
      regex: regex
    })
  end

  defp extract_command(cmd),
    do:
      cmd
      |> String.split(" ")
      |> Enum.at(0)
      |> String.replace_prefix("/", "")

  defp handle_text(text, %Cnt{commands: commands, regex: regex}) do
    if String.starts_with?(text, "/") do
      cmd = extract_command(text)
      t = text |> String.split(" ") |> Enum.drop(1) |> Enum.join(" ")

      case Enum.find(commands, &(Keyword.get(&1, :command) == cmd)) do
        nil ->
          {:command, cmd, t}

        cmd ->
          {:command, Keyword.get(cmd, :name), t}
      end
    else
      case Enum.find(regex, &Regex.match?(Keyword.get(&1, :regex), text)) do
        nil ->
          {:text, text}

        reg ->
          {:regex, Keyword.get(reg, :name), text}
      end
    end
  end

  defp extract_info(%Cnt{update: %{message: %{text: t} = message}} = cnt) when is_bitstring(t) do
    case handle_text(t, cnt) do
      {:command, key, text} -> {:command, key, %{message | text: text}}
      {:text, text} -> {:text, text, %{message | text: text}}
      {:regex, key, text} -> {:regex, key, %{message | text: text}}
    end
  end

  defp extract_info(%Cnt{update: %{message: %{location: location}}}) when not is_nil(location) do
    {:location, location}
  end

  defp extract_info(%Cnt{update: %{message: message}}) when not is_nil(message) do
    {:message, message}
  end

  defp extract_info(%Cnt{update: %{callback_query: cbq}}) when not is_nil(cbq) do
    {:callback_query, cbq}
  end

  # edited_message
  # channel_post
  # edited_channel_post
  # inline_query
  # chosen_inline_result
  # shipping_query
  # pre_checkout_query
  defp extract_info(%Cnt{update: u}) do
    {:update, u}
  end

  defp apply_middlewares(%Cnt{middlewares: []} = cnt), do: cnt
  defp apply_middlewares(%Cnt{halted: true} = cnt), do: cnt
  defp apply_middlewares(%Cnt{middleware_halted: true} = cnt), do: cnt

  defp apply_middlewares(%Cnt{middlewares: [{midd, ops} | xs]} = cnt) when is_function(midd) do
    cnt = cnt |> Map.put(:middlewares, xs)
    new_cnt = midd.(cnt, ops)
    apply_middlewares(new_cnt)
  end

  defp apply_middlewares(%Cnt{middlewares: [{midd, ops} | xs]} = cnt) when is_atom(midd) do
    cnt = cnt |> Map.put(:middlewares, xs)
    init_ops = midd.init(ops)
    new_cnt = midd.call(cnt, init_ops)
    apply_middlewares(new_cnt)
  end

  defp apply_middlewares(%Cnt{middlewares: [_ | xs]} = cnt),
    do: cnt |> Map.put(:middlewares, xs) |> apply_middlewares()

  defp call_handler(handler, info, cnt, error_handler) do
    case handler.(info, cnt) do
      %Cnt{} = cnt ->
        cnt
        |> ExGram.Dsl.send_answers()
        |> handle_responses(error_handler)

      _ ->
        :noop
    end
  end

  defp handle_responses(%Cnt{responses: responses}, error_handler),
    do: handle_responses(responses, error_handler, [])

  defp handle_responses([], _error_handler, acc), do: acc

  defp handle_responses([{:error, error} | rest], error_handler, acc) do
    error_handler.(error)
    handle_responses(rest, error_handler, acc)
  end

  defp handle_responses([value | rest], error_handler, acc) do
    handle_responses(rest, error_handler, acc ++ [value])
  end
end
