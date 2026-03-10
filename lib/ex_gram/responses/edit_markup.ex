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

  @doc """
  Updates the inline message's reply markup by adding the inline_message_id to the ops and performing the edit.
  """
  @spec execute(%{inline_message_id: term(), ops: keyword()}) :: any()
  def execute(%{inline_message_id: mid, ops: ops}) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    ExGram.edit_message_reply_markup(new_ops)
  end

  @doc """
  Populate a response's identifying fields from a message when the response has no message identifiers set.
  
  If the response's `message_id`, `chat_id`, and `inline_message_id` are all nil, merges the appropriate identifier fields extracted from `msg` into the response; otherwise leaves the response unchanged.
  
  ## Parameters
  
    - response: Response map or struct whose identifier fields will be filled if currently nil.
    - msg: A message struct or map from which `chat_id`/`message_id` or `inline_message_id` will be extracted.
  
  """
  @spec set_msg(map(), any()) :: map()
  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, msg_params(msg))
  end

  @doc """
Return the response unchanged when it already contains message identifiers.

If the response has a `message_id`/`chat_id` pair or an `inline_message_id`, the provided `msg` is ignored and the original response is returned unchanged.
"""
@spec set_msg(t(), any()) :: t()
def set_msg(response, _msg), do: response

  defp msg_params(%_struct{} = msg), do: ExGram.Dsl.extract_inline_id_params(msg)

  defp msg_params(%{chat_id: chat_id, message_id: message_id}) do
    %{chat_id: chat_id, message_id: message_id}
  end

  defp msg_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}
end
