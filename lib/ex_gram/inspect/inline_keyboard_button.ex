defimpl Inspect, for: ExGram.Model.InlineKeyboardButton do
  import Inspect.Algebra

  @action_fields [
    {:callback_data, "cb"},
    {:url, "url"},
    {:web_app, "web_app"},
    {:login_url, "login_url"},
    {:switch_inline_query, "switch_iq"},
    {:switch_inline_query_current_chat, "switch_iq_cc"},
    {:switch_inline_query_chosen_chat, "switch_iq_chosen"},
    {:copy_text, "copy"},
    {:callback_game, "game"},
    {:pay, "pay"}
  ]

  @other_fields [:icon_custom_emoji_id, :style]

  def inspect(button, opts) do
    action_parts =
      @action_fields
      |> Enum.filter(fn {field, _} -> Map.get(button, field) not in [nil, false] end)
      |> Enum.map(fn {field, _} ->
        concat([string(Atom.to_string(field) <> ": "), to_doc(Map.get(button, field), opts)])
      end)

    other_parts =
      @other_fields
      |> Enum.filter(fn field -> Map.get(button, field) != nil end)
      |> Enum.map(fn field -> concat([string(Atom.to_string(field) <> ": "), to_doc(Map.get(button, field), opts)]) end)

    all_parts = other_parts ++ action_parts

    quoted_text = to_doc(button.text, opts)

    inner =
      case all_parts do
        [] ->
          quoted_text

        parts ->
          concat([quoted_text, string(" "), fold_doc(parts, fn a, b -> glue(concat(a, ","), b) end)])
      end

    concat(["#InlineKeyboardButton<", inner, ">"])
  end
end
