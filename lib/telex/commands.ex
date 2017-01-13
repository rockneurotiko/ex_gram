defmodule Telex.Commands do
  @doc """
  Test
  """
  defmacro command(command) do
    # if command.module_info[:attributes][:behaviour] == nil do
    #   raise "The command #{inspect(command)} don't have any behaviour"
    # end

    quote do
      # @commands {{:cmd, unquote(command)}}
      @commands unquote(command)
    end
  end

  def handle_command(handler, %{text: t} = m) do
    if t == handler.cmd do
      handler.execute(m)
    end
  end
  # @doc """
  # Test 2
  # """
  # defmacro custom(check, cmd) when is_function(check) and is_function(cmd) do
  #   quote do
  #     @commands {unquote(check), unquote(cmd)}
  #   end
  # end
end
