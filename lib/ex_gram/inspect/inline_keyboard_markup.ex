defimpl Inspect, for: ExGram.Model.InlineKeyboardMarkup do
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

  def inspect(markup, opts) do
    verbose = Keyword.get(opts.custom_options, :verbose, false)
    rows = Enum.map_intersperse(markup.inline_keyboard, line(), &render_row(&1, verbose))

    inner = concat(rows)

    force_unfit(
      concat([
        "#InlineKeyboardMarkup<",
        nest(concat([line(), inner]), 2),
        line(),
        ">"
      ])
    )
  end

  defp render_row(buttons, verbose) do
    buttons
    |> Enum.map(&render_button(&1, verbose))
    |> concat()
  end

  defp render_button(button, verbose) do
    action =
      Enum.find_value(@action_fields, fn {field, abbrev} ->
        value = Map.get(button, field)

        if value not in [nil, false] do
          {abbrev, value}
        end
      end)

    label =
      case action do
        nil ->
          button.text

        {abbrev, _value} when not verbose ->
          "#{button.text} (#{abbrev})"

        {abbrev, value} when is_binary(value) ->
          "#{button.text} (#{abbrev}: #{inspect(value)})"

        {abbrev, value} when is_boolean(value) ->
          "#{button.text} (#{abbrev}: #{value})"

        {abbrev, value} ->
          short_name = value |> Map.get(:__struct__) |> Module.split() |> List.last()
          "#{button.text} (#{abbrev}: #{short_name})"
      end

    string("[ #{label} ]")
  end
end
