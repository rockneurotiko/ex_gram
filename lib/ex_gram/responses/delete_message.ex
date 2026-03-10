defmodule ExGram.Responses.DeleteMessage do
  @moduledoc """
  Delete message response using `ExGram.delete_message/3`.

  Used by `ExGram.Dsl` for deleting message responses.
  """

  defstruct [:chat_id, :message_id, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.DeleteMessage do
  def new(response, params), do: struct(response, params)

  @doc """
  Delete the message identified in the given response struct.
  
  Uses the struct's `chat_id` and `message_id`. If `ops` is nil, an empty list is used.
  ## Parameters
  
    - cb: Response struct containing `chat_id`, `message_id`, and an optional `ops` list.
  """
  @spec execute(map()) :: any()
  def execute(cb) do
    ExGram.delete_message(cb.chat_id, cb.message_id, cb.ops || [])
  end

  @doc """
  Populate a response's chat_id and message_id when both fields are nil.
  
  Updates the given response struct by setting `chat_id` and `message_id` from the provided map containing those keys.
  """
  @spec set_msg(map(), %{chat_id: any(), message_id: any()}) :: map()
  def set_msg(%{chat_id: nil, message_id: nil} = response, %{chat_id: chat_id, message_id: message_id}) do
    %{response | chat_id: chat_id, message_id: message_id}
  end

  @doc """
  Populate `chat_id` and `message_id` on a response whose `chat_id` and `message_id` are nil by extracting those identifiers from the provided message.
  
  ## Parameters
  
    - msg: a message structure containing chat and message identifiers.
  
  ## Examples
  
      iex> set_msg(%{chat_id: nil, message_id: nil}, message)
      %{chat_id: 123, message_id: 45, ...}
  
  """
  @spec set_msg(map(), any()) :: map()
  def set_msg(%{chat_id: nil, message_id: nil} = response, msg) do
    %{
      response
      | chat_id: ExGram.Dsl.extract_id(msg),
        message_id: ExGram.Dsl.extract_message_id(msg)
    }
  end

  def set_msg(response, _msg), do: response
end
