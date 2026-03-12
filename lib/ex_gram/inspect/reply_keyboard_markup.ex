defimpl Inspect, for: ExGram.Model.ReplyKeyboardMarkup do
  import Inspect.Algebra

  @option_fields [
    {:is_persistent, "persistent"},
    {:resize_keyboard, "resize"},
    {:one_time_keyboard, "one_time"},
    {:input_field_placeholder, "placeholder"},
    {:selective, "selective"}
  ]

  def inspect(markup, opts) do
    options =
      @option_fields
      |> Enum.filter(fn {field, _} -> Map.get(markup, field) not in [nil, false] end)
      |> Enum.map(fn {field, short} -> concat([string(short <> ": "), to_doc(Map.get(markup, field), opts)]) end)

    rows = Enum.map_intersperse(markup.keyboard, line(), &render_row/1)

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

  defp render_row(buttons) do
    buttons
    |> Enum.map(fn button -> string("[ #{button.text} ]") end)
    |> concat()
  end
end
