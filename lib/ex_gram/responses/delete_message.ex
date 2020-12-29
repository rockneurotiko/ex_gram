defmodule ExGram.Responses.DeleteMessage do
  @moduledoc """
  Delete message response
  """

  defstruct [:chat_id, :message_id, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.DeleteMessage do
  def new(response, params), do: struct(response, params)

  def execute(cb) do
    ExGram.delete_message(cb.chat_id, cb.message_id, cb.ops)
  end

  def set_msg(%{chat_id: nil, message_id: nil} = response, msg) do
    %{
      response
      | chat_id: ExGram.Dsl.extract_id(msg),
        message_id: ExGram.Dsl.extract_message_id(msg)
    }
  end

  def set_msg(response, _msg), do: response
end
