defmodule Telex.Dispatcher do
  use GenServer

  require Logger

  # commands: [command: "echo", name: :echo]
  # regex: [regex: "^/echo", name: :echor]

  def start_link(%{name: name} = ops) do
    GenServer.start_link(__MODULE__, {:ok, ops}, [name: name])
  end

  def init({:ok, ops}) do
    {:ok, ops}
  end

  # defp is_implemented?(handler, behaviour) do
  #   case handler.module_info[:attributes][:behaviour] do
  #     nil -> false
  #     ls -> Enum.any?(ls, fn l -> l == behaviour end)
  #   end
  # end

  # defp handle_test_execute(handler, base, u) do
  #   if not is_nil(u) and is_implemented?(handler, base) do
  #     ht = handler.test(u)
  #     if ht do
  #       handler.execute(u)
  #     end
  #     ht
  #   else
  #     false
  #   end
  # end

  # Handle messages!
  # defp handle_message(handler,  u) do
  #   handle_test_execute(handler, Telex.Dsl.Message, u)
  # end

  # defp handle_callback_query(handler, u) do
  #   handle_test_execute(handler, Telex.Dsl.CallbackQuery, u)
  # end

  # defp dispatch_update(handler, u) do
  #   handle_test_execute(handler, Telex.Dsl.Base, u) ||
  #     handle_message(handler, u.message) ||
  #     handle_test_execute(handler, Telex.Dsl.EditedMessage, u.edited_message) ||
  #     handle_test_execute(handler, Telex.Dsl.ChannelPost, u.channel_post) ||
  #     handle_test_execute(handler, Telex.Dsl.EditedChannelPost, u.edited_channel_post) ||
  #     handle_test_execute(handler, Telex.Dsl.InlineQuery, u.inline_query) ||
  #     handle_test_execute(handler, Telex.Dsl.ChosenInlineResult, u.chosen_inline_result) ||
  #     handle_callback_query(handler, u.callback_query)
  # end


  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  defp clean_command(cmd), do: cmd |> String.split(" ") |> Enum.at(0) |> String.replace_prefix("/", "") |> String.split("@") |> Enum.at(0)

  defp handle_text(text, %{commands: commands, regex: regex}) do
    if String.starts_with?(text, "/") do
      cmd = clean_command(text)
      t = text |> String.split(" ") |> Enum.drop(1) |> Enum.join(" ")
      case Enum.find(commands, &(Keyword.get(&1, :command) == cmd)) do
        nil ->
          {:command, cmd, t}
        cmd ->
          {:command, Keyword.get(cmd, :name), t}
      end
    else
      case Enum.find(regex, &(Regex.match?(Keyword.get(&1, :regex), text))) do
        nil ->
          {:text, text}
        reg ->
          {:regex, Keyword.get(reg, :name), text}
      end
    end
  end

  defp extract_info(%{message: %{text: t} = message}, s) when is_bitstring(t) do
    case handle_text(t, s) do
      {:command, key, text} -> {:command, key, %{message | text: text}}
      {:text, text} -> {:text, text, %{message | text: text}}
      {:regex, key, text} -> {:regex, key, %{message | text: text}}
    end
  end

  defp extract_info(%{message: message}, _s) when not is_nil(message) do
    {:message, message}
  end

  defp extract_info(%{callback_query: cbq}, _s) when not is_nil(cbq) do
    {:callback_query, cbq}
  end

  defp extract_info(update, _s) do
    {:update, update}
  end

  defp apply_middlewares([], st), do: st
  defp apply_middlewares(_, {:error, _} = st), do: st
  defp apply_middlewares([x|xs], {:ok, state}) when is_function(x) do
    state = x.(state)
    apply_middlewares(xs, state)
  end
  defp apply_middlewares([x|xs], {:ok, state}) when is_atom(x) do
    state = x.apply(state)
    apply_middlewares(xs, state)
  end
  defp apply_middlewares([_|xs], state), do: apply_middlewares(xs, state)

  def handle_call({:update, u}, _from, %{handler: handler, name: name, middlewares: middlewares} = s) do
    Logger.info "Update received: #{inspect u}"
    case apply_middlewares(middlewares, {:ok, %{update: u}}) do
      {:ok, extra} when is_map(extra) ->
        u = Map.get(extra, :update, u) # Get the update from the middlewares
        info = extract_info(u, s)
        spawn fn -> handler.(info, name, extra) end
      _ ->
        Logger.info "Middleware cancel"
    end
    {:reply, :ok, s}
  end

  def handle_call({:update, u}, _from, s) do
    Logger.error "Update, not update? #{inspect(u)}\nState: #{inspect(s)}"
    {:reply, :error, s}
  end

  def handle_call({:message, origin, msg}, from, %{handler: handler, name: name} = s) do
    response = handler.({:bot_message, origin, msg}, name, %{from: from})
    {:reply, response, s}
  end

  def handle_call(msg, from, %{handler: handler, name: name} = s) do
    response = handler.({:call, msg}, name, %{from: from})
    {:reply, response, s}
  end

  def handle_cast(msg, %{handler: handler, name: name} = s) do
    spawn fn -> handler.({:cast, msg}, name, %{}) end
    {:noreply, s}
  end
end
