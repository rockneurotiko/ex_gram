if Code.ensure_loaded?(MDEx) do
  defmodule ExGram.Markdown do
    @moduledoc """
    Converts CommonMark/GFM Markdown into a `{plain_text, [MessageEntity]}` tuple
    for the Telegram Bot API.

    Uses MDEx (backed by Rust's `comrak`) for spec-compliant parsing, then walks
    the AST to produce plain text annotated with `%ExGram.Model.MessageEntity{}`
    structs whose `offset` and `length` fields are measured in UTF-16 code units
    (as required by Telegram).

    ## Options

      * `:skip_blockquotes` — when `true`, blockquote nodes are rendered as
        indented plain text instead of a `blockquote` entity. Useful when the
        output will itself be wrapped in an expandable blockquote, since Telegram
        forbids nested blockquotes.

    ## Fallback

    If MDEx fails to parse, the raw markdown is returned as plain text with no
    entities.

    ## Example

        iex> ExGram.Markdown.to_entities("**bold** and *italic*")
        {"bold and italic",
         [
           %ExGram.Model.MessageEntity{type: "bold", offset: 0, length: 4},
           %ExGram.Model.MessageEntity{type: "italic", offset: 9, length: 6}
         ]}

    """

    alias ExGram.Dsl.MessageEntityBuilder, as: B

    @parse_opts [
      extension: [
        strikethrough: true,
        table: true,
        tasklist: true,
        autolink: true,
        spoiler: true
      ]
    ]

    @doc """
    Converts a Markdown string into a `{plain_text, [MessageEntity]}` tuple.
    """
    @spec to_entities(String.t(), keyword()) :: B.t()
    def to_entities(markdown, opts \\ []) when is_binary(markdown) do
      skip_blockquotes = Keyword.get(opts, :skip_blockquotes, false)

      try do
        doc = MDEx.parse_document!(markdown, @parse_opts)
        ctx = %{skip_blockquotes: skip_blockquotes, list_type: nil, list_depth: 0}
        render_nodes(doc.nodes, ctx)
      rescue
        _ -> B.text(markdown)
      end
    end

    # ---------------------------------------------------------------------------
    # Node rendering — returns {text, entities} tuples
    # ---------------------------------------------------------------------------

    defp render_nodes(nodes, ctx) when is_list(nodes) do
      nodes
      |> Enum.map(&render_node(&1, ctx))
      |> B.concat()
    end

    # Document root — just recurse
    defp render_node(%MDEx.Document{nodes: nodes}, ctx), do: render_nodes(nodes, ctx)

    # Inline formatting — wrap children in the entity
    defp render_node(%MDEx.Strong{nodes: nodes}, ctx) do
      B.wrap("bold", render_nodes(nodes, ctx))
    end

    defp render_node(%MDEx.Emph{nodes: nodes}, ctx) do
      B.wrap("italic", render_nodes(nodes, ctx))
    end

    defp render_node(%MDEx.Strikethrough{nodes: nodes}, ctx) do
      B.wrap("strikethrough", render_nodes(nodes, ctx))
    end

    defp render_node(%MDEx.Underline{nodes: nodes}, ctx) do
      B.wrap("underline", render_nodes(nodes, ctx))
    end

    defp render_node(%MDEx.SpoileredText{nodes: nodes}, ctx) do
      B.wrap("spoiler", render_nodes(nodes, ctx))
    end

    # Inline code — entity over the literal text (no escaping needed)
    defp render_node(%MDEx.Code{literal: literal}, _ctx) do
      B.code(literal)
    end

    # Fenced code block — pre entity with optional language
    defp render_node(%MDEx.CodeBlock{info: info, literal: literal}, _ctx) do
      lang = info && String.trim(info)
      lang = if lang == "", do: nil, else: lang
      # Strip trailing newline from literal (comrak always adds one)
      text = String.trim_trailing(literal, "\n")
      B.pre(text, lang)
    end

    # Link — text_link entity
    defp render_node(%MDEx.Link{url: url, nodes: nodes}, ctx) do
      {inner_text, inner_entities} = render_nodes(nodes, ctx)

      inner_text
      |> B.text_link(url)
      |> then(fn {t, [link_entity]} ->
        # Preserve nested entities (bold/italic inside link text)
        {t, [link_entity | inner_entities]}
      end)
    end

    # Image — render alt text only (Telegram can't display images in text)
    defp render_node(%MDEx.Image{nodes: nodes}, ctx) do
      render_nodes(nodes, ctx)
    end

    # Headings — render as bold with surrounding newlines
    defp render_node(%MDEx.Heading{nodes: nodes}, ctx) do
      inner = render_nodes(nodes, ctx)
      B.concat([B.text("\n"), B.wrap("bold", inner), B.text("\n")])
    end

    # Paragraph — add double newline after
    defp render_node(%MDEx.Paragraph{nodes: nodes}, ctx) do
      inner = render_nodes(nodes, ctx)
      B.concat([inner, B.text("\n\n")])
    end

    # Blockquote — either a blockquote entity or indented plain text
    defp render_node(%MDEx.BlockQuote{nodes: nodes}, %{skip_blockquotes: true} = ctx) do
      # Indent with 2 spaces per line instead of entity
      {inner_text, inner_entities} = render_nodes(nodes, ctx)
      trimmed = String.trim(inner_text)

      indented =
        trimmed
        |> String.split("\n")
        |> Enum.map_join("\n", &"  #{&1}")

      # Entities need to be shifted per line to account for the 2-space indent.
      # Rather than complex per-line offset arithmetic, we rebuild with plain indentation.
      # Inner entities cannot be easily preserved with line-by-line indentation;
      # we preserve them by offsetting uniformly (works for single-line blockquotes
      # and is a best-effort for multi-line ones).
      indent_offset = 2

      adjusted_entities = B.offset_entities(inner_entities, indent_offset)

      {indented <> "\n", adjusted_entities}
    end

    defp render_node(%MDEx.BlockQuote{nodes: nodes}, ctx) do
      inner = render_nodes(nodes, ctx)
      {inner_text, _} = inner
      trimmed = String.trim_trailing(inner_text, "\n")
      inner_trimmed = {trimmed, elem(inner, 1)}
      B.concat([B.blockquote(inner_trimmed), B.text("\n")])
    end

    # Lists
    defp render_node(%MDEx.List{list_type: list_type, start: start, nodes: nodes}, ctx) do
      child_ctx = %{ctx | list_type: list_type, list_depth: ctx.list_depth + 1}

      nodes
      |> Enum.with_index(start || 1)
      |> Enum.map(fn {item, idx} -> render_list_item(item, idx, child_ctx) end)
      |> B.concat()
    end

    defp render_node(%MDEx.ListItem{} = item, ctx) do
      # ListItem outside a List context — render children directly
      render_nodes(item.nodes, ctx)
    end

    # Task list item (GFM checkbox)
    defp render_node(%MDEx.TaskItem{checked: checked, nodes: nodes}, ctx) do
      prefix = if checked, do: "☑ ", else: "☐ "
      indent = String.duplicate("  ", max(ctx.list_depth - 1, 0))
      inner = render_nodes(nodes, ctx)
      {inner_text, inner_entities} = inner
      trimmed = String.trim(inner_text)

      prefix_text = indent <> prefix

      offset =
        B.offset_entities(inner_entities, B.utf16_length(prefix_text))

      {prefix_text <> trimmed <> "\n", offset}
    end

    # Table — render as a code block (pre entity), plain text only
    defp render_node(%MDEx.Table{nodes: nodes}, _ctx) do
      rows =
        Enum.map(nodes, fn row ->
          Enum.map_join(row.nodes, " | ", fn cell ->
            cell.nodes |> render_plain_text() |> String.trim()
          end)
        end)

      case rows do
        [] ->
          B.empty()

        [header | rest] ->
          body = Enum.join([header, "---" | rest], "\n")
          B.pre(body, nil)
      end
    end

    # Thematic break (---) — em-dash separator
    defp render_node(%MDEx.ThematicBreak{}, _ctx), do: B.text("———\n")

    # Soft and hard breaks
    defp render_node(%MDEx.SoftBreak{}, _ctx), do: B.text("\n")
    defp render_node(%MDEx.LineBreak{}, _ctx), do: B.text("\n")

    # Plain text — no escaping needed (not MarkdownV2)
    defp render_node(%MDEx.Text{literal: literal}, _ctx), do: B.text(literal)

    # Raw HTML — strip tags, plain text
    defp render_node(%MDEx.HtmlInline{literal: literal}, _ctx), do: B.text(strip_html_tags(literal))

    defp render_node(%MDEx.HtmlBlock{literal: literal}, _ctx), do: B.text(strip_html_tags(literal))

    # Unknown nodes with children — recurse gracefully
    defp render_node(node, ctx) do
      case Map.get(node, :nodes) do
        nodes when is_list(nodes) -> render_nodes(nodes, ctx)
        _ -> B.empty()
      end
    end

    # ---------------------------------------------------------------------------
    # List item rendering
    # ---------------------------------------------------------------------------

    defp render_list_item(%MDEx.ListItem{nodes: nodes}, idx, ctx) do
      indent = String.duplicate("  ", max(ctx.list_depth - 1, 0))

      prefix =
        case ctx.list_type do
          :ordered -> "#{idx}. "
          _ -> "• "
        end

      prefix_str = indent <> prefix

      # Paragraphs inside list items — don't add double newlines
      inner =
        nodes
        |> Enum.map(fn
          %MDEx.Paragraph{nodes: children} -> render_nodes(children, ctx)
          child -> render_node(child, ctx)
        end)
        |> B.concat()

      {inner_text, inner_entities} = inner
      trimmed = String.trim(inner_text)
      offset = B.utf16_length(prefix_str)
      adjusted_entities = B.offset_entities(inner_entities, offset)
      {prefix_str <> trimmed <> "\n", adjusted_entities}
    end

    defp render_list_item(node, _idx, ctx), do: render_node(node, ctx)

    # ---------------------------------------------------------------------------
    # Plain-text extraction (for table cells — no entities)
    # ---------------------------------------------------------------------------

    defp render_plain_text(nodes) when is_list(nodes) do
      Enum.map_join(nodes, "", &render_plain_text/1)
    end

    defp render_plain_text(%MDEx.SoftBreak{}), do: " "
    defp render_plain_text(%MDEx.LineBreak{}), do: "\n"
    defp render_plain_text(%{literal: literal}) when is_binary(literal), do: literal
    defp render_plain_text(%{nodes: nodes}) when is_list(nodes), do: render_plain_text(nodes)
    defp render_plain_text(_), do: ""

    # ---------------------------------------------------------------------------
    # HTML stripping
    # ---------------------------------------------------------------------------

    defp strip_html_tags(html) when is_binary(html) do
      Regex.replace(~r/<[^>]*>/, html, "")
    end
  end
end
