defmodule Telex.Dsl do
  defmacro __using__([]) do
    quote do
      import Telex.Dsl
      import Telex.Dsl.Command
      import Telex.Dsl.Regex
      import Telex.Dsl.Message
      import Telex.Dsl.Update
    end
  end

  @doc """
  Test
  """
  defmacro dispatch(command) do
    quote do
      if is_nil(unquote(command).module_info[:attributes][:behaviour]) do
        [behaviour] = unquote(command).module_info[:attributes][:behaviour]

        if not Enum.member?([Telex.Dsl.Base, Telex.Dsl.Message], behaviour) do
          raise "The command #{inspect(unquote(command))} don't provide a valid behaviour"
        end
      end

      @dispatchers unquote(command)
    end
  end

  def create_inline_button(row) do
    row
    |> Enum.map(fn ops ->
         Map.merge(%Telex.Model.InlineKeyboardButton{}, Enum.into(ops, %{}))
       end)
  end

  def create_inline(data \\ [[]]) do
    data =
      data
      |> Enum.map(&create_inline_button/1)

    %Telex.Model.InlineKeyboardMarkup{inline_keyboard: data}
  end

  def extract_id(u) do
    with {:ok, %{id: gid}} <- extract_group(u) do
      gid
    else
      _ ->
        case extract_user(u) do
          {:ok, %{id: uid}} -> uid
          _ -> -1
        end
    end
  end

  def extract_user(%{from: u}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{callback_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chosen_inline_result: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{inline_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(_), do: :error

  def extract_group(%{chat: c}) when not is_nil(c), do: {:ok, c}
  def extract_group(%{message: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{callback_query: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{channel_post: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{chosen_inline_result: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{edited_channel_post: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{edited_message: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{inline_query: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(_), do: :error

  # def answer(m, text, ops \\ []), do: answer(m, text, nil, ops)
  def answer(m, text, ops) do
    Telex.send_message(extract_id(m), text, ops)
  end

  def answer_callback(id, ops) do
    Telex.answer_callback_query(id, ops)
  end

  defp inline_id(ops, %{message: %{message_id: mid}} = m),
    do: ops |> Keyword.put(:message_id, mid) |> Keyword.put(:chat_id, extract_id(m))

  defp inline_id(ops, %{inline_message_id: mid}), do: ops |> Keyword.put(:inline_message_id, mid)
  # defp inline_id(ops, _), do: ops

  def edit(:inline, m, text, ops) do
    ops = inline_id(ops, m)
    Telex.edit_message_text(text, ops)
  end

  def edit(:markup, m, _, ops) do
    edit(:markup, m, ops)
  end

  def edit(_, _, _, _), do: {:error, "Wrong params"}

  def edit(:markup, m, ops) do
    ops = inline_id(ops, m)
    Telex.edit_message_reply_markup(ops)
  end
end
