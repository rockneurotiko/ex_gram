defmodule ExGram.Responses.EditMarkup do
  @moduledoc """
  Edit markup response. It will detect the message and use it accordingly to edit the normal or inline message markup.
  """

  defstruct [:message_id, :chat_id, :inline_message_id, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.EditMarkup do
  def new(response, params), do: struct(response, params)

  def execute(%{inline_message_id: nil, ops: ops} = markup) do
    new_ops =
      ops |> Keyword.put(:message_id, markup.message_id) |> Keyword.put(:chat_id, markup.chat_id)

    ExGram.edit_message_reply_markup(new_ops)
  end

  def execute(%{inline_message_id: mid, ops: ops}) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    ExGram.edit_message_reply_markup(new_ops)
  end

  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, ExGram.Dsl.extract_inline_id_params(msg))
  end

  def set_msg(response, _msg), do: response
end
