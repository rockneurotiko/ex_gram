defmodule ExGram.Dsl.Keyboard do
  @moduledoc """
  Keyboard DSL to create inline keyboards easily

  Example:

  ``` elixir
  keyb = keyboard :inline do
    row do
      button "A", callback_data: "a", style: "green"
      button "B", switch_inline_query_current_chat: "b"
    end

    row do
      button "C", callback_data: "C", style: "red"
      button "D", copy_text: "D"
    end
  end
  ```
  """

  def remove_keyboard(:reply, selective? \\ nil) do
    %ExGram.Model.ReplyKeyboardRemove{remove_keyboard: true, selective: selective?}
  end

  @spec keyboard(:inline | :reply, keyword(), do: any()) ::
          ExGram.Model.InlineKeyboardMarkup.t() | ExGram.Model.ReplyKeyboardMarkup.t()
  defmacro keyboard(type, opts \\ [], do_block)

  defmacro keyboard(:inline, _opts, do: block) do
    rows = wrap_block(block)

    quote do
      unquote(rows)
      |> Enum.reject(&(is_nil(&1) or Enum.empty?(&1)))
      |> ExGram.Dsl.create_inline_keyboard()
    end
  end

  defmacro keyboard(:reply, opts, do: block) do
    rows = wrap_block(block)

    quote do
      unquote(rows)
      |> Enum.reject(&(is_nil(&1) or Enum.empty?(&1)))
      |> ExGram.Dsl.create_reply_keyboard(unquote(opts))
    end
  end

  defmacro row(do: block) do
    buttons = wrap_block(block)

    quote do
      unquote(buttons)
      |> Enum.reject(&is_nil/1)
    end
  end

  # Here for backwards compatibility
  def button(text, opts \\ []) do
    inline_button(text, opts)
  end

  def inline_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(ExGram.Model.InlineKeyboardButton, opts)
  end

  def reply_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(ExGram.Model.KeyboardButton, opts)
  end

  defp wrap_block({:__block__, _, exprs}), do: exprs
  defp wrap_block(single), do: [single]
end
