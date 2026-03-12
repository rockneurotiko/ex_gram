defimpl Inspect, for: ExGram.Model.KeyboardButton do
  import Inspect.Algebra

  @optional_fields [
    :icon_custom_emoji_id,
    :style,
    :request_users,
    :request_chat,
    :request_contact,
    :request_location,
    :request_poll,
    :web_app
  ]

  def inspect(button, opts) do
    parts =
      @optional_fields
      |> Enum.filter(fn field -> Map.get(button, field) not in [nil, false] end)
      |> Enum.map(fn field -> concat([string(Atom.to_string(field) <> ": "), to_doc(Map.get(button, field), opts)]) end)

    quoted_text = "\"#{button.text}\""

    inner =
      case parts do
        [] ->
          string(quoted_text)

        parts ->
          concat([string(quoted_text <> " "), fold_doc(parts, fn a, b -> glue(concat(a, ","), b) end)])
      end

    concat(["#KeyboardButton<", inner, ">"])
  end
end
