defmodule Telex.Commands do
  @doc """
  Test
  """
  defmacro command(command) do
    quote do
      @commands {{:cmd, unquote(command)}}
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
