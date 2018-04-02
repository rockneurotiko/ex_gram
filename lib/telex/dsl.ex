defmodule Telex.Dsl do
  alias Telex.Cnt
  alias Telex.Responses
  alias Telex.Responses.{Answer, AnswerCallback, EditInline, EditMarkup}

  def answer(cnt, text), do: answer(cnt, text, [])

  def answer(cnt, text, ops) when is_binary(text) and is_list(ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> add_answer(cnt)
  end

  def answer(cnt, m, text) when is_map(m) and is_binary(text), do: answer(cnt, m, text, [])

  def answer(cnt, m, text, ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> Responses.set_msg(m) |> add_answer(cnt)
  end

  def answer_callback(cnt, ops) do
    AnswerCallback |> Responses.new(%{ops: ops}) |> add_answer(cnt)
  end

  def answer_callback(cnt, id, ops) do
    AnswerCallback |> Responses.new(%{ops: ops}) |> Responses.set_msg(id) |> add_answer(cnt)
  end

  # /3
  def edit(cnt, :inline, text) when is_binary(text), do: edit(cnt, :inline, text, [])

  def edit(cnt, :markup, ops) when is_list(ops) do
    EditMarkup |> Responses.new(%{ops: ops}) |> add_answer(cnt)
  end

  # /4
  def edit(cnt, :inline, text, ops) when is_binary(text) do
    EditInline |> Responses.new(%{text: text, ops: ops}) |> add_answer(cnt)
  end

  def edit(cnt, :markup, m, ops) do
    EditMarkup |> Responses.new(%{ops: ops}) |> Responses.set_msg(m) |> add_answer(cnt)
  end

  # /5
  def edit(cnt, :inline, m, text, ops) do
    EditInline
    |> Responses.new(%{text: text, ops: ops})
    |> Responses.set_msg(m)
    |> add_answer(cnt)
  end

  def edit(cnt, :markup, m, _, ops) do
    edit(cnt, :markup, m, ops)
  end

  def edit(_cnt, _, _, _, _), do: raise("Wrong params")

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

  def extract_callback_id(%{callback_query: m}) when not is_nil(m), do: extract_callback_id(m)
  def extract_callback_id(%{id: cid, data: _data}), do: cid
  def extract_callback_id(cid) when is_binary(cid), do: cid
  def extract_callback_id(_), do: :error

  def extract_inline_id_params(%{message: %{message_id: mid}} = m),
    do: %{message_id: mid, chat_id: extract_id(m)}

  def extract_inline_id_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}

  def send_answers(%Cnt{halted: true} = cnt), do: cnt

  def send_answers(%Cnt{answers: answers, name: name, halted: false} = cnt) do
    msg = extract_msg(cnt)
    send_all_answers(answers, name, msg)
    %{cnt | halted: true}
  end

  defp add_answer(resp, %Cnt{answers: answers} = cnt) do
    answers = answers ++ [{:response, resp}]
    %{cnt | answers: answers}
  end

  defp extract_msg(%Cnt{update: %Telex.Model.Update{} = u}) do
    u = Map.from_struct(u)
    {_, msg} = Enum.find(u, fn {_, m} -> is_map(m) and not is_nil(m) end)
    msg
  end

  defp extract_msg(_), do: nil

  defp send_all_answers([], _, _), do: :ok

  defp send_all_answers([{:response, response} | answers], name, msg) do
    response |> put_name_if_not(name) |> Telex.Responses.set_msg(msg) |> Telex.Responses.execute()
    send_all_answers(answers, name, msg)
  end

  defp send_all_answers([_ | answers], name, msg), do: send_all_answers(answers, name, msg)

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
