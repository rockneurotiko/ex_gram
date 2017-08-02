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

  def extract_id(u) do
    with {:ok, gid} <- extract_group_id(u) do
      gid
    else
      _ ->
        case extract_user_id(u) do
          {:ok, uid} -> uid
          _ -> -1
        end
    end
  end

  def extract_user_id(%{message: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{callback_query: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{channel_post: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{chosen_inline_result: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{edited_message: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{inline_query: m}) when not is_nil(m), do: extract_user_id(m)
  def extract_user_id(%{from: u}) when not is_nil(u), do: {:ok, u[:id]}
  def extract_user_id(_), do: :error

  def extract_group_id(%{message: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{callback_query: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{channel_post: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{chosen_inline_result: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{edited_message: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{inline_query: m}) when not is_nil(m), do: extract_group_id(m)
  def extract_group_id(%{chat: c}) when not is_nil(c), do: {:ok, c[:id]}
  def extract_group_id(_), do: :error

  # def answer(m, text, ops \\ []), do: answer(m, text, nil, ops)
  def answer(m, text, ops) do
    Telex.send_message(extract_id(m), text, ops)
  end

  def answer_callback(id, ops) do
    Telex.answer_callback_query(id, ops)
  end


  defp inline_id(ops, %{message: %{message_id: mid}} = m), do: ops |> Keyword.put(:message_id, mid) |> Keyword.put(:chat_id, extract_id(m))
  defp inline_id(ops, %{inline_message_id: mid}), do: ops |> Keyword.put(:inline_message_id, mid)
  # defp inline_id(ops, _), do: ops

  def edit(:inline, m, text, ops) do
    ops = inline_id(ops, m)
    Telex.edit_message_text(text, ops)
  end

  def edit(:markup, m, _, ops) do
    edit(:markup, m, ops)
  end

  def edit(_, _, _, _), do: {:error, "Wrong params"}

  def edit(:markup, m, ops) do
    ops = inline_id(ops, m)
    Telex.edit_message_reply_markup(ops)
  end




end
