defmodule Telex.Dsl do
  alias Telex.Responses
  alias Telex.Responses.{Answer, AnswerCallback, EditInline, EditMarkup}

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

  def create_inline_button(row) do
    row
    |> Enum.map(fn ops ->
         Map.merge(%Telex.Model.InlineKeyboardButton{}, Enum.into(ops, %{}))
       end)
  end

  def create_inline(data \\ [[]]) do
    data =
      data
      |> Enum.map(&create_inline_button/1)

    %Telex.Model.InlineKeyboardMarkup{inline_keyboard: data}
  end

  def extract_id(u) do
    with {:ok, %{id: gid}} <- extract_group(u) do
      gid
    else
      _ ->
        case extract_user(u) do
          {:ok, %{id: uid}} -> uid
          _ -> -1
        end
    end
  end

  def extract_user(%{from: u}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{callback_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chosen_inline_result: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{inline_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(_), do: :error

  def extract_group(%{chat: c}) when not is_nil(c), do: {:ok, c}
  def extract_group(%{message: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{callback_query: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{channel_post: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{chosen_inline_result: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{edited_channel_post: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{edited_message: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(%{inline_query: m}) when not is_nil(m), do: extract_group(m)
  def extract_group(_), do: :error

  def extract_callback_id(%{callback_query: m}) when not is_nil(m), do: extract_callback_id(m)
  def extract_callback_id(%{id: cid, data: _data}), do: cid
  def extract_callback_id(cid) when is_binary(cid), do: cid
  def extract_callback_id(_), do: :error

  def extract_inline_id_params(%{message: %{message_id: mid}} = m),
    do: %{message_id: mid, chat_id: extract_id(m)}

  def extract_inline_id_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}

  def answer(text), do: answer(text, [])

  def answer(text, ops) when is_binary(text) and is_list(ops) do
    {:response, Responses.new(Answer, %{text: text, ops: ops})}
  end

  def answer(m, text) when is_map(m) and is_binary(text), do: answer(m, text, [])

  def answer(m, text, ops) do
    response = Answer |> Responses.new(%{text: text, ops: ops}) |> Responses.set_msg(m)

    {:response, response}
  end

  def answer!(m, text, ops \\ []) do
    answer(m, text, ops) |> execute_response()
  end

  def answer_callback(ops) do
    {:response, Responses.new(AnswerCallback, %{ops: ops})}
  end

  def answer_callback(id, ops) do
    response = AnswerCallback |> Responses.new(%{ops: ops}) |> Responses.set_msg(id)
    {:response, response}
  end

  def answer_callback!(id, ops) do
    answer_callback(id, ops) |> execute_response
  end

  # /2
  def edit(:inline, text) when is_binary(text), do: edit(:inline, text, [])

  def edit(:markup, ops) when is_list(ops) do
    {:response, Responses.new(EditMarkup, %{ops: ops})}
  end

  # /3
  def edit(:inline, text, ops) when is_binary(text) do
    {:response, Responses.new(EditInline, %{text: text, ops: ops})}
  end

  def edit(:markup, m, ops) do
    response = EditMarkup |> Responses.new(%{ops: ops}) |> Responses.set_msg(m)
    {:response, response}
  end

  # /4
  def edit(:inline, m, text, ops) do
    response = EditInline |> Responses.new(%{text: text, ops: ops}) |> Responses.set_msg(m)
    {:response, response}
  end

  def edit(:markup, m, _, ops) do
    edit(:markup, m, ops)
  end

  def edit(_, _, _, _), do: {:error, "Wrong params"}

  def edit!(mode, msg, text, ops) do
    edit(mode, msg, text, ops) |> execute_response()
  end

  defp execute_response({:response, response}), do: Responses.execute(response)

  defp execute_response(other), do: other
end
