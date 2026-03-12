defimpl Inspect, for: ExGram.Model.ReplyKeyboardMarkup do
  import Inspect.Algebra

  @option_fields [
    {:is_persistent, "persistent"},
    {:resize_keyboard, "resize"},
    {:one_time_keyboard, "one_time"},
    {:input_field_placeholder, "placeholder"},
    {:selective, "selective"}
  ]

  @button_fields [
    :icon_custom_emoji_id,
    :style,
    :request_users,
    :request_chat,
    :request_contact,
    :request_location,
    :request_poll,
    :web_app
  ]

  def inspect(markup, opts) do
    verbose = Keyword.get(opts.custom_options, :verbose, false)

    options =
      @option_fields
      |> Enum.filter(fn {field, _} -> Map.get(markup, field) not in [nil, false] end)
      |> Enum.map(fn {field, short} -> concat([string(short <> ": "), to_doc(Map.get(markup, field), opts)]) end)

    rows = Enum.map_intersperse(markup.keyboard, line(), &render_row(&1, verbose))

    keyboard_doc = concat(rows)

    options_doc =
      case options do
        [] ->
          empty()

        opts_list ->
          concat([
            fold_doc(opts_list, fn a, b -> glue(concat(a, ","), b) end),
            ","
          ])
      end

    inner =
      case options do
        [] ->
          concat([line(), keyboard_doc])

        _ ->
          concat([options_doc, line(), keyboard_doc])
      end

    force_unfit(
      concat([
        "#ReplyKeyboardMarkup<",
        nest(inner, 2),
        line(),
        ">"
      ])
    )
  end

  defp render_row(buttons, verbose) do
    row =
      buttons
      |> Enum.map(&render_button(&1, verbose))
      |> concat()

    concat(["[ ", row, " ]"])
  end

  defp render_button(button, false) do
    string("[ #{button.text} ]")
  end

  defp render_button(button, true) do
    extra =
      @button_fields
      |> Enum.filter(fn field -> Map.get(button, field) not in [nil, false] end)
      |> Enum.map(fn field ->
        value = Map.get(button, field)

        value_str =
          cond do
            is_binary(value) -> inspect(value)
            is_boolean(value) -> to_string(value)
            true -> value |> Map.get(:__struct__) |> Module.split() |> List.last()
          end

        "#{field}: #{value_str}"
      end)

    case extra do
      [] -> string("[ #{button.text} ]")
      parts -> string("[ #{button.text} (#{Enum.join(parts, ", ")}) ]")
    end
  end
end
