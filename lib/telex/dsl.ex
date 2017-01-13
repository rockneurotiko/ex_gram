defmodule Telex.Dsl do

  defp extract_id(%{chat: c}) when not is_nil(c), do: c[:id]
  defp extract_id(%{from: u}) when not is_nil(u), do: u[:id]

  def answer(m, text, ops \\ []) do
    Telex.send_message(extract_id(m), text, ops)
  end
end
