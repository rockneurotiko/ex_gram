defmodule Telex.Responses.AnswerCallback do
  defstruct [:id, :ops]
end

defimpl Telex.Responses, for: Telex.Responses.AnswerCallback do
  def new(response, params), do: struct(response, params)

  def execute(cb) do
    Telex.answer_callback_query(cb.id, cb.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    %{response | id: Telex.Dsl.extract_callback_id(msg)}
  end

  def set_msg(response, _msg), do: response
end
