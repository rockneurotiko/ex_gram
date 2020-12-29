defmodule ExGram.Responses.AnswerCallback do
  @moduledoc """
  Answer callback query response
  """

  defstruct [:id, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.AnswerCallback do
  def new(response, params), do: struct(response, params)

  def execute(cb) do
    ExGram.answer_callback_query(cb.id, cb.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    %{response | id: ExGram.Dsl.extract_callback_id(msg)}
  end

  def set_msg(response, _msg), do: response
end
