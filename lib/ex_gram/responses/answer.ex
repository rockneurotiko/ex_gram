defmodule ExGram.Responses.Answer do
  @moduledoc """
  Simple text answer, it uses `send_message`
  """

  defstruct [:id, :text, :ops]
end

defimpl ExGram.Responses, for: ExGram.Responses.Answer do
  def new(response, params), do: struct(response, params)

  def execute(answer) do
    ExGram.send_message(answer.id, answer.text, answer.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    %{response | id: ExGram.Dsl.extract_id(msg)}
  end

  def set_msg(response, _msg), do: response
end
