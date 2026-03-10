defmodule ExGram.Responses.EditInline do
  @moduledoc """
  Edit inline message response using `ExGram.edit_message_text/2`.

  This response type edits the text content of either a regular message or an inline
  message. It automatically detects which type based on the provided message identifiers.

  Used by `ExGram.Dsl` for editing message responses.
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

  @doc """
  Sends an edit request to update the text of an inline message using the response's `inline_message_id` and options.
  """
  @spec execute(%__MODULE__{}) :: {:ok, any()} | {:error, any()}
  def execute(%{inline_message_id: mid, ops: ops} = edit) do
    new_ops = Keyword.put(ops, :inline_message_id, mid)

    ExGram.edit_message_text(edit.text, new_ops)
  end

  @doc """
  Populate a response that currently lacks identifiers by merging identifier parameters extracted from `msg` into the response.
  
  When the response has `message_id`, `chat_id`, and `inline_message_id` all nil, this function extracts the appropriate identifier fields from `msg` (struct or map) and merges them into the response.
  
  ## Parameters
  
    - response: A response map/struct with `message_id`, `chat_id`, and `inline_message_id` all set to `nil`.
    - msg: The message to extract identifiers from. May be a message struct, a map with `chat_id` and `message_id`, or a map with `inline_message_id`.
  
  """
  @spec set_msg(map(), map() | struct()) :: map()
  def set_msg(%{message_id: nil, chat_id: nil, inline_message_id: nil} = response, msg) do
    Map.merge(response, msg_params(msg))
  end

  @doc """
Leaves the response unchanged when message identifiers are already present.

This clause is used when no update from the provided `msg` is required; the `msg` argument is ignored.
"""
@spec set_msg(ExGram.Responses.EditInline.t(), any()) :: ExGram.Responses.EditInline.t()
def set_msg(response, _msg), do: response

  defp msg_params(%_struct{} = msg), do: ExGram.Dsl.extract_inline_id_params(msg)

  defp msg_params(%{chat_id: chat_id, message_id: message_id}) do
    %{chat_id: chat_id, message_id: message_id}
  end

  defp msg_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}
end
