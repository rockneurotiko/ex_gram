defmodule ExGram.Responses.SendDocument do
  @moduledoc """
  Send document response, it uses `ExGram.send_document/3`
  """

  defstruct [:id, :document, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.SendDocument do
  def new(response, params), do: struct(response, params)

  def execute(answer) do
    ExGram.send_document(answer.id, answer.document, answer.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    %{response | id: ExGram.Dsl.extract_id(msg)}
  end

  def set_msg(response, _msg), do: response
end
