defmodule ExGram.Dsl.Keyboard do
  @moduledoc """
  Keyboard DSL to create inline keyboards easily

  Example:

  ``` elixir
  keyb = keyboard :inline do
    row do
      button "A", callback_data: "a"
      button "B", callback_data: "b"
    end

    row do
      button "C", callback_data: "c"
      button "D", callback_data: "d"
    end
  end
  ```
  """

  defmacro keyboard(which_keyboard, do: block) do
    build_keyboard_f =
      case which_keyboard do
        :inline -> &ExGram.Dsl.create_inline/1
      end

    quote do
      var!(keyboard_variable_1) = []

      unquote(block)

      unquote(build_keyboard_f).(var!(keyboard_variable_1))
    end
  end

  defmacro row(do: block) do
    quote do
      var!(keyboard_variable_row) = []

      unquote(block)

      var!(keyboard_variable_1) = var!(keyboard_variable_1) ++ [var!(keyboard_variable_row)]
    end
  end

  defmacro button(text, opts \\ []) do
    quote do
      var!(keyboard_variable_row) =
        var!(keyboard_variable_row) ++ [Keyword.merge([text: unquote(text)], unquote(opts))]
    end
  end
end
