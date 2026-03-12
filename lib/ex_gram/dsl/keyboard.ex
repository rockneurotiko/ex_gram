defmodule ExGram.Dsl.Keyboard do
  @moduledoc """
  Keyboard DSL to create inline and reply keyboards easily.

  This DSL provides a clean syntax for building `ExGram.Model.InlineKeyboardMarkup`
  and `ExGram.Model.ReplyKeyboardMarkup` structures without manually constructing
  nested button arrays.

  ## Example

  ``` elixir
  keyb = keyboard :inline do
    row do
      button "A", callback_data: "a", style: "success"
      button "B", switch_inline_query_current_chat: "b"
    end

    row do
      button "C", callback_data: "C", style: "danger"
      button "D", copy_text: "D"
    end
  end
  ```

  See the [Sending Messages guide](sending-messages.md) for more examples.
  """

  # Macros:
  alias ExGram.Model.InlineKeyboardButton
  alias ExGram.Model.KeyboardButton
  alias ExGram.Model.ReplyKeyboardRemove

  @spec keyboard(:inline, do: any()) :: Macro.t()
  @spec keyboard(:inline, keyword(), do: any()) :: Macro.t()
  defmacro keyboard(type, opts \\ [], do_block)

  defmacro keyboard(:inline, opts, do: block) do
    rows = wrap_block(block)

    quote do
      ExGram.Dsl.Keyboard.build_keyboard(:inline, unquote(rows), unquote(opts))
    end
  end

  @spec keyboard(:reply, do: any()) :: Macro.t()
  @spec keyboard(:reply, keyword(), do: any()) :: Macro.t()
  defmacro keyboard(:reply, opts, do: block) do
    rows = wrap_block(block)

    quote do
      ExGram.Dsl.Keyboard.build_keyboard(:reply, unquote(rows), unquote(opts))
    end
  end

  @spec build_keyboard(:inline, [[InlineKeyboardButton.t()] | nil], keyword()) ::
          ExGram.Model.InlineKeyboardMarkup.t()
  def build_keyboard(:inline, rows, _) do
    rows |> normalize_rows() |> Enum.reject(&Enum.empty?/1) |> ExGram.Dsl.create_inline_keyboard()
  end

  @spec build_keyboard(:reply, [[KeyboardButton.t()] | nil], keyword()) ::
          ExGram.Model.ReplyKeyboardMarkup.t()
  def build_keyboard(:reply, rows, opts) do
    rows
    |> normalize_rows()
    |> Enum.reject(&Enum.empty?/1)
    |> ExGram.Dsl.create_reply_keyboard(opts)
  end

  @spec row(do: any()) :: Macro.t()
  defmacro row(do: block) do
    buttons = wrap_block(block)

    quote do
      Enum.reject(unquote(buttons), &is_nil/1)
    end
  end

  # Other public methods:

  @spec remove_keyboard(:reply, boolean() | nil) :: ReplyKeyboardRemove.t()
  def remove_keyboard(:reply, selective? \\ nil) do
    %ReplyKeyboardRemove{remove_keyboard: true, selective: selective?}
  end

  # Here for backwards compatibility
  @spec button(String.t(), keyword()) :: InlineKeyboardButton.t()
  def button(text, opts \\ []) do
    inline_button(text, opts)
  end

  @spec inline_button(String.t(), keyword()) :: InlineKeyboardButton.t()
  def inline_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(InlineKeyboardButton, opts)
  end

  @spec reply_button(String.t(), keyword()) :: KeyboardButton.t()
  def reply_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(KeyboardButton, opts)
  end

  # Normalizes the rows list at runtime, allowing dynamic expressions (e.g. Enum.map)
  # to produce multiple rows by returning a list of button lists.
  #
  # Rules:
  #   - nil entries are dropped
  #   - A bare button struct is wrapped into a single-button row
  #   - A list of button structs is kept as a single row (one row, N buttons)
  #   - A list of lists (each inner list being a row) is unnested one level,
  #     so Enum.map returning [button(...)] per element yields one row per element
  defp normalize_rows(rows) do
    Enum.flat_map(rows, &normalize_row/1)
  end

  defp normalize_row(nil), do: []
  defp normalize_row(%InlineKeyboardButton{} = btn), do: [[btn]]
  defp normalize_row(%KeyboardButton{} = btn), do: [[btn]]

  defp normalize_row(row) when is_list(row) do
    row = Enum.reject(row, &is_nil/1)

    if Enum.all?(row, &button?/1) do
      [row]
    else
      normalize_rows(row)
    end
  end

  defp button?(%InlineKeyboardButton{}), do: true
  defp button?(%KeyboardButton{}), do: true
  defp button?(_), do: false

  defp wrap_block({:__block__, _, exprs}), do: exprs
  defp wrap_block(single), do: [single]
end
