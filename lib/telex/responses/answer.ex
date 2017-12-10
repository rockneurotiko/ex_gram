defmodule Telex.Responses.Answer do
  defstruct [:id, :text, :ops]
end

defimpl Telex.Responses, for: Telex.Responses.Answer do
  def new(response, params), do: struct(response, params)

  def execute(answer) do
    Telex.send_message(answer.id, answer.text, answer.ops)
  end

  def set_msg(%{id: nil} = response, msg) do
    %{response | id: Telex.Dsl.extract_id(msg)}
  end

  def set_msg(response, _msg), do: response
end
