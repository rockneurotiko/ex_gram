defmodule ExGram.Responses.AnswerInlineQuery do
  @moduledoc """
  Answer inline query response
  """

  defstruct [:id, :articles, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.AnswerInlineQuery do
  def new(response, params), do: struct(response, params)

  def execute(cb) do
    ExGram.answer_inline_query(cb.id, cb.articles, cb.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    id = ExGram.Dsl.extract_response_id(msg)
    %{response | id: id}
  end

  def set_msg(response, _msg), do: response
end
