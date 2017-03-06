defmodule Telex.Dsl do

  defmacro __using__([]) do
    quote do
      import Telex.Dsl
      import Telex.Dsl.Command
      import Telex.Dsl.Regex
      import Telex.Dsl.Message
      import Telex.Dsl.Update
    end
  end

  @doc """
  Test
  """
  defmacro dispatch(command) do
    quote do
      if is_nil(unquote(command).module_info[:attributes][:behaviour]) do
        [behaviour] = unquote(command).module_info[:attributes][:behaviour]
        if not Enum.member?([Telex.Dsl.Base, Telex.Dsl.Message], behaviour) do
          raise "The command #{inspect(unquote(command))} don't provide a valid behaviour"
        end
      end

      @dispatchers unquote(command)
    end
  end

  def extract_id(%{chat: c}) when not is_nil(c), do: c[:id]
  def extract_id(%{from: u}) when not is_nil(u), do: u[:id]

  # def answer(m, text, ops \\ []), do: answer(m, text, nil, ops)
  def answer(m, text, ops) do
    Telex.send_message(extract_id(m), text, ops)
  end
end
