defmodule Telex.Dispatcher do
  use GenServer

  def start_link(%{dispatcher_name: name} = ops) do
    GenServer.start_link(__MODULE__, {:ok, ops}, name: name)
  end

  def init({:ok, ops}) do
    {:ok, ops}
  end

  # EditedMessage
  # ChannelPost
  # EditedChannelPost
  # InlineQuery
  # ChosenInlineResult

  defp clean_command(cmd),
    do:
      cmd
      |> String.split(" ")
      |> Enum.at(0)
      |> String.replace_prefix("/", "")
      |> String.split("@")
      |> Enum.at(0)

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
      case Enum.find(regex, &Regex.match?(Keyword.get(&1, :regex), text)) do
        nil ->
          {:text, text}

        reg ->
          {:regex, Keyword.get(reg, :name), text}
      end
    end
  end

  defp extract_msg({_, _, msg}), do: msg
  defp extract_msg({_, msg}), do: msg

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

  # edited_message
  # channel_post
  # edited_channel_post
  # inline_query
  # chosen_inline_result
  # shipping_query
  # pre_checkout_query

  defp extract_info(update, _s) do
    {:update, update}
  end

  defp apply_middlewares([], st), do: st
  defp apply_middlewares(_, {:error, _} = st), do: st

  defp apply_middlewares([x | xs], {:ok, state}) when is_function(x) do
    state = x.(state)
    apply_middlewares(xs, state)
  end

  defp apply_middlewares([x | xs], {:ok, state}) when is_atom(x) do
    state = x.apply(state)
    apply_middlewares(xs, state)
  end

  defp apply_middlewares([_ | xs], state), do: apply_middlewares(xs, state)

  def handle_call(
        {:update, u},
        _from,
        %{handler: handler, name: name, middlewares: middlewares} = s
      ) do
    case apply_middlewares(middlewares, {:ok, %{update: u}}) do
      {:ok, extra} when is_map(extra) ->
        # Get the update from the middlewares
        u = Map.get(extra, :update, u)
        info = extract_info(u, s)
        spawn(fn -> call_handler(handler, info, name, extra) end)

      _ ->
        # Logger.info "Middleware cancel"
        true
    end

    {:reply, :ok, s}
  end

  def handle_call({:update, _u}, _from, s) do
    # Logger.error "Update, not update? #{inspect(u)}\nState: #{inspect(s)}"
    {:reply, :error, s}
  end

  def handle_call({:message, origin, msg}, from, %{handler: handler, name: name} = s) do
    response = call_handler(handler, {:bot_message, origin, msg}, name, %{from: from})
    {:reply, response, s}
  end

  def handle_call(msg, from, %{handler: handler, name: name} = s) do
    response = call_handler(handler, {:call, msg}, name, %{from: from})
    {:reply, response, s}
  end

  def handle_cast(msg, %{handler: handler, name: name} = s) do
    spawn(fn -> call_handler(handler, {:cast, msg}, name, %{}) end)
    {:noreply, s}
  end

  defp call_handler(handler, info, name, extra) do
    case handler.(info, name, extra) do
      {:response, response} ->
        msg = extract_msg(info)
        new_response = response |> put_name_if_not(name) |> Telex.Responses.set_msg(msg)
        Telex.Responses.execute(new_response)

      _ ->
        :noop
    end
  end

  defp put_name_if_not(%{ops: ops} = base, name) when is_list(ops) do
    %{base | ops: put_name_if_not(ops, name)}
  end

  defp put_name_if_not(keyword, name) do
    case {Keyword.fetch(keyword, :token), Keyword.fetch(keyword, :bot)} do
      {:error, :error} -> Keyword.put(keyword, :bot, name)
      _ -> keyword
    end
  end
end
