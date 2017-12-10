defmodule Telex.Responses.EditMarkup do
  defstruct [:message_id, :chat_id, :inline_message_id, :ops]
end

defimpl Telex.Responses, for: Telex.Responses.EditMarkup do
  def new(response, params), do: struct(response, params)

  def execute(%{inline_message_id: nil, ops: ops} = markup) do
    new_ops =
      ops |> Keyword.put(:message_id, markup.message_id) |> Keyword.put(:chat_id, markup.chat_id)

    Telex.edit_message_reply_markup(new_ops)
  end

  def execute(%{inline_message_id: mid, ops: ops}) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    Telex.edit_message_reply_markup(new_ops)
  end

  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, Telex.Dsl.extract_inline_id_params(msg))
  end

  def set_msg(response, _msg), do: response
end
