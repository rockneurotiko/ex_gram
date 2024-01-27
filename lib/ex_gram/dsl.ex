defmodule ExGram.Dsl do
  @moduledoc """
  Mini DSL to build answers based on the context easily.
  """

  alias ExGram.Cnt
  alias ExGram.Responses
  alias ExGram.Responses.Answer
  alias ExGram.Responses.AnswerCallback
  alias ExGram.Responses.AnswerInlineQuery
  alias ExGram.Responses.DeleteMessage
  alias ExGram.Responses.EditInline
  alias ExGram.Responses.EditMarkup
  alias ExGram.Responses.SendDocument

  def answer(cnt, text, ops \\ [])

  def answer(cnt, text, ops) when is_binary(text) and is_list(ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> add_answer(cnt)
  end

  def answer(cnt, m, text) when is_map(m) and is_binary(text), do: answer(cnt, m, text, [])

  def answer(cnt, m, text, ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> Responses.set_msg(m) |> add_answer(cnt)
  end

  def answer_callback(cnt, msg, ops \\ []) do
    AnswerCallback |> Responses.new(%{ops: ops}) |> Responses.set_msg(msg) |> add_answer(cnt)
  end

  def answer_inline_query(cnt, articles, ops \\ []) do
    AnswerInlineQuery |> Responses.new(%{articles: articles, ops: ops}) |> add_answer(cnt)
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

  def delete(cnt, msg, ops \\ []) do
    DeleteMessage |> Responses.new(%{ops: ops}) |> Responses.set_msg(msg) |> add_answer(cnt)
  end

  defguardp is_file(file) when is_binary(file) or (is_tuple(file) and elem(file, 0) == :file)

  def answer_document(cnt, document, ops \\ [])

  def answer_document(cnt, document, ops) when is_file(document) and is_list(ops) do
    SendDocument
    |> Responses.new(%{document: document, ops: ops})
    |> add_answer(cnt)
  end

  def answer_document(cnt, msg, document) when is_map(msg) and is_file(document),
    do: answer_document(cnt, msg, document, [])

  def answer_document(cnt, msg, document, ops) when is_map(msg) and is_file(document) do
    SendDocument
    |> Responses.new(%{document: document, ops: ops})
    |> Responses.set_msg(msg)
    |> add_answer(cnt)
  end

  def create_inline_button(row) do
    Enum.map(row, fn ops -> Map.merge(%ExGram.Model.InlineKeyboardButton{}, Map.new(ops)) end)
  end

  def create_inline(data \\ [[]]) do
    data =
      Enum.map(data, &create_inline_button/1)

    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: data}
  end

  def extract_id(u) do
    case extract_group(u) do
      {:ok, %{id: gid}} ->
        gid

      _ ->
        case extract_user(u) do
          {:ok, %{id: uid}} -> uid
          _ -> -1
        end
    end
  end

  def extract_user(%{from: u}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{my_chat_member: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chat_member: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chat_join_request: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{callback_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chosen_inline_result: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{inline_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{shipping_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{pre_checkout_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{poll_answer: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(_), do: :error

  def extract_group(%{chat: c}) when not is_nil(c), do: {:ok, c}
  def extract_group(%{message: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{my_chat_member: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{chat_member: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{chat_join_request: m}) when not is_nil(m), do: extract_group(m)
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

  def extract_response_id(%{message_id: id}) when not is_nil(id), do: id
  def extract_response_id(%{id: id}) when not is_nil(id), do: id
  def extract_response_id(%{message: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{callback_query: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{inline_query: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{edited_message: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{channel_message: m}) when not is_nil(m), do: extract_response_id(m)

  def extract_response_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_response_id(m)

  def extract_message_id(%{message_id: id}), do: id
  def extract_message_id(%{message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{edited_message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{channel_message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(_), do: :error

  def extract_update_type(%{message: m}) when not is_nil(m), do: :message
  def extract_update_type(%{edited_message: m}) when not is_nil(m), do: :edited_message
  def extract_update_type(%{channel_post: m}) when not is_nil(m), do: :channel_post
  def extract_update_type(%{edited_channel_post: m}) when not is_nil(m), do: :edited_channel_post
  def extract_update_type(%{inline_query: m}) when not is_nil(m), do: :inline_query
  def extract_update_type(%{chosen_inline_result: m}) when not is_nil(m), do: :chosen_inline_result
  def extract_update_type(%{callback_query: m}) when not is_nil(m), do: :callback_query
  def extract_update_type(%{shipping_query: m}) when not is_nil(m), do: :shipping_query
  def extract_update_type(%{pre_checkout_query: m}) when not is_nil(m), do: :pre_checkout_query
  def extract_update_type(%{poll: m}) when not is_nil(m), do: :poll
  def extract_update_type(%{poll_answer: m}) when not is_nil(m), do: :poll_answer
  def extract_update_type(%{my_chat_member: m}) when not is_nil(m), do: :my_chat_member
  def extract_update_type(%{chat_member: m}) when not is_nil(m), do: :chat_member
  def extract_update_type(%{chat_join_request: m}) when not is_nil(m), do: :chat_join_request
  def extract_update_type(_), do: :error

  def extract_message_type(%{entities: [%{type: "bot_command"}]}), do: :command
  def extract_message_type(%{text: m}) when not is_nil(m), do: :text
  def extract_message_type(%{animation: m}) when not is_nil(m), do: :animation
  def extract_message_type(%{audio: m}) when not is_nil(m), do: :audio
  def extract_message_type(%{document: m}) when not is_nil(m), do: :document
  def extract_message_type(%{photo: m}) when not is_nil(m), do: :photo
  def extract_message_type(%{sticker: m}) when not is_nil(m), do: :sticker
  def extract_message_type(%{video: m}) when not is_nil(m), do: :video
  def extract_message_type(%{video_note: m}) when not is_nil(m), do: :video_note
  def extract_message_type(%{voice: m}) when not is_nil(m), do: :voice
  def extract_message_type(%{contact: m}) when not is_nil(m), do: :contact
  def extract_message_type(%{dice: m}) when not is_nil(m), do: :dice
  def extract_message_type(%{game: m}) when not is_nil(m), do: :game
  def extract_message_type(%{poll: m}) when not is_nil(m), do: :poll
  def extract_message_type(%{venue: m}) when not is_nil(m), do: :venue
  def extract_message_type(%{location: m}) when not is_nil(m), do: :location
  def extract_message_type(%{message: m}) when not is_nil(m), do: extract_message_type(m)
  def extract_message_type(_), do: :error

  def extract_inline_id_params(%{message: %{message_id: mid}} = m), do: %{message_id: mid, chat_id: extract_id(m)}

  def extract_inline_id_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}

  def send_answers(%Cnt{halted: true} = cnt), do: cnt

  def send_answers(%Cnt{answers: answers, name: name, halted: false} = cnt) do
    msg = extract_msg(cnt)
    responses = send_all_answers(answers, name, msg)
    %{cnt | responses: responses, halted: true}
  end

  defp add_answer(resp, %Cnt{answers: answers} = cnt) do
    answers = answers ++ [{:response, resp}]
    %{cnt | answers: answers}
  end

  defp extract_msg(%Cnt{update: %ExGram.Model.Update{} = u}) do
    u = Map.from_struct(u)
    {_, msg} = Enum.find(u, fn {_, m} -> is_map(m) and not is_nil(m) end)
    msg
  end

  defp extract_msg(_), do: nil

  defp send_all_answers(answers, name, msg), do: send_all_answers(answers, name, msg, [])

  defp send_all_answers([], _, _, responses), do: responses

  defp send_all_answers([{:response, answer} | answers], name, msg, responses) do
    response =
      answer
      |> put_name_if_not(name)
      |> ExGram.Responses.set_msg(msg)
      |> ExGram.Responses.execute()

    responses = responses ++ [response]

    send_all_answers(answers, name, msg, responses)
  end

  defp send_all_answers([answer | answers], name, msg, responses) do
    error = %ExGram.Error{
      code: :unknown_answer,
      message: "Unknown answer: #{inspect(answer)}",
      metadata: %{answer: answer}
    }

    responses = responses ++ [{:error, error}]
    send_all_answers(answers, name, msg, responses)
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
