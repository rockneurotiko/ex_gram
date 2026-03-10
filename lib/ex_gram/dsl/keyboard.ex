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

  @doc """
  Builds an inline keyboard markup from a list of button rows.
  
  Filters out `nil` and empty rows from `rows` before constructing an `InlineKeyboardMarkup`.
  
  ## Parameters
  
    - rows: A list of rows where each row is a list of `InlineKeyboardButton` structs; `nil` or empty rows will be ignored.
    - _opts: Keyword options (currently ignored).
  
  ## Returns
  
    - An `ExGram.Model.InlineKeyboardMarkup` representing the inline keyboard.
  """
  @spec build_keyboard(:inline, [[InlineKeyboardButton.t()] | nil], keyword()) ::
            ExGram.Model.InlineKeyboardMarkup.t()
  def build_keyboard(:inline, rows, _) do
    rows |> Enum.reject(&(is_nil(&1) or Enum.empty?(&1))) |> ExGram.Dsl.create_inline_keyboard()
  end

  @doc """
  Builds a reply keyboard markup from a list of button rows.
  
  Filters out `nil` or empty rows before constructing the reply keyboard. The `opts`
  are forwarded to the reply keyboard creator to control keyboard behaviour.
  
  ## Parameters
  
    - rows: a list of rows, each row being a list of `KeyboardButton` structs; `nil` or empty rows are ignored.
    - opts: keyword list of options forwarded to the reply keyboard creator.
  
  ## Returns
  
  An `ExGram.Model.ReplyKeyboardMarkup` struct representing the assembled reply keyboard.
  """
  @spec build_keyboard(:reply, [[KeyboardButton.t()] | nil], keyword()) ::
            ExGram.Model.ReplyKeyboardMarkup.t()
  def build_keyboard(:reply, rows, opts) do
    rows |> Enum.reject(&(is_nil(&1) or Enum.empty?(&1))) |> ExGram.Dsl.create_reply_keyboard(opts)
  end

  @spec row(do: any()) :: Macro.t()
  defmacro row(do: block) do
    buttons = wrap_block(block)

    quote do
      Enum.reject(unquote(buttons), &is_nil/1)
    end
  end

  # Other public methods:

  @doc """
  Creates a ReplyKeyboardRemove struct that tells Telegram to remove the current reply keyboard.
  
  ## Parameters
  
    - selective?: When `true`, instructs Telegram to remove the keyboard for specific users only; when `false` or `nil`, no selective flag is set and the removal is not limited to specific users.
  """
  @spec remove_keyboard(:reply, boolean() | nil) :: ReplyKeyboardRemove.t()
  def remove_keyboard(:reply, selective? \\ nil) do
    %ReplyKeyboardRemove{remove_keyboard: true, selective: selective?}
  end

  # Here for backwards compatibility
  @doc """
  Creates an inline keyboard button with the given text label.
  
  The `opts` keyword list may include additional button fields (for example `:callback_data`, `:url`, etc.).
  """
  @spec button(String.t(), keyword()) :: InlineKeyboardButton.t()
  def button(text, opts \\ []) do
    inline_button(text, opts)
  end

  @doc """
  Constructs an InlineKeyboardButton with the given display text and additional fields.
  
  ## Parameters
  
    - text: The label shown on the button.
    - opts: Keyword list of additional button fields (for example `:url`, `:callback_data`, etc.) to set on the resulting `InlineKeyboardButton`.
  """
  @spec inline_button(String.t(), keyword()) :: InlineKeyboardButton.t()
  def inline_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(InlineKeyboardButton, opts)
  end

  @doc """
  Creates a KeyboardButton with the given display text and additional options.
  
  ## Parameters
  
    - opts: keyword list of KeyboardButton fields, e.g. `:request_contact`, `:request_location`.
  
  ## Examples
  
      iex> reply_button("Share contact", request_contact: true)
      %KeyboardButton{text: "Share contact", request_contact: true}
  
  """
  @spec reply_button(String.t(), keyword()) :: KeyboardButton.t()
  def reply_button(text, opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:text, text)
    struct!(KeyboardButton, opts)
  end

  defp wrap_block({:__block__, _, exprs}), do: exprs
  defp wrap_block(single), do: [single]
end
