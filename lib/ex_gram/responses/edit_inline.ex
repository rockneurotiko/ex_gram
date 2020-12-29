defmodule ExGram.Responses.EditInline do
  @moduledoc """
  Edit inline message response. It will detect the message and use it accordingly to edit the normal or inline message.
  """

  defstruct [:text, :message_id, :chat_id, :inline_message_id, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.EditInline do
  def new(response, params), do: struct(response, params)

  def execute(%{inline_message_id: nil, ops: ops} = edit) do
    new_ops =
      ops |> Keyword.put(:message_id, edit.message_id) |> Keyword.put(:chat_id, edit.chat_id)

    ExGram.edit_message_text(edit.text, new_ops)
  end

  def execute(%{inline_message_id: mid, ops: ops} = edit) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    ExGram.edit_message_text(edit.text, new_ops)
  end

  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, ExGram.Dsl.extract_inline_id_params(msg))
  end

  def set_msg(response, _msg), do: response
end
