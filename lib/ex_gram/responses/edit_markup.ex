defmodule ExGram.Responses.EditMarkup do
  @moduledoc """
  Edit markup response using `ExGram.edit_message_reply_markup/1`.

  This response type edits the reply markup (inline keyboard) of either a regular
  message or an inline message. It automatically detects which type based on the
  provided message identifiers.

  Used by `ExGram.Dsl` for editing keyboard responses.
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
    Map.merge(response, msg_params(msg))
  end

  def set_msg(response, _msg), do: response

  defp msg_params(%_struct{} = msg), do: ExGram.Dsl.extract_inline_id_params(msg)

  defp msg_params(%{chat_id: chat_id, message_id: message_id}) do
    %{chat_id: chat_id, message_id: message_id}
  end

  defp msg_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}
end
