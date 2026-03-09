if Code.ensure_loaded?(MDEx) do
  defmodule ExGram.Markdown do
    @moduledoc """
    Converts CommonMark/GFM Markdown into a `{plain_text, [MessageEntity]}` tuple
    for the Telegram Bot API.

    Uses [MDEx](https://hexdocs.pm/mdex) (backed by Rust's `comrak`) for spec-compliant
    parsing, then walks the AST to produce plain text annotated with `ExGram.Model.MessageEntity`
    structs whose `offset` and `length` fields are measured in UTF-16 code units
    (as required by Telegram).

    ## Options

      * `:skip_blockquotes` - when `true`, blockquote nodes are rendered as
        indented plain text instead of a `blockquote` entity. Useful when the
        output will itself be wrapped in an expandable blockquote, since Telegram
        forbids nested blockquotes.

    ## Fallback

    If [MDEx](https://hexdocs.pm/mdex) fails to parse, the raw markdown is returned
    as plain text with no entities.

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
    Converts a Markdown string into a `t:ExGram.Dsl.MessageEntityBuilder.t/0` ready to be used.
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

    @doc """
    Converts a `t:ExGram.Dsl.MessageEntityBuilder.t/0` back into a markdown string.

    > #### Warning {: .warning}
    >
    > The conversion from markdown <-> entities is not 1 on 1, since entities is a limited
    > subset of markdown.

    ## Formats

      * `:markdown` - CommonMark output (via [MDEx](https://hexdocs.pm/mdex) AST)
      * `:markdown_v2` - Telegram MarkdownV2 output with proper escaping

    ## Example

        iex> alias ExGram.Model.MessageEntity
        iex> entities = [%MessageEntity{type: "bold", offset: 0, length: 4}]
        iex> ExGram.Markdown.from_entities({"bold text", entities}, :markdown)
        "**bold** text"
        iex> ExGram.Markdown.from_entities({"bold text", entities}, :markdown_v2)
        "*bold* text"

    """
    @spec from_entities(B.t(), :markdown | :markdown_v2) :: String.t()
    def from_entities({text, entities}, format \\ :markdown) when is_binary(text) and is_list(entities) do
      tree = build_entity_tree(text, entities)

      case format do
        :markdown -> tree_to_commonmark(tree)
        :markdown_v2 -> tree_to_markdown_v2(tree)
      end
    end

    # ---------------------------------------------------------------------------
    # Node rendering: returns {text, entities} tuples
    # ---------------------------------------------------------------------------

    defp render_nodes(nodes, ctx) when is_list(nodes) do
      nodes
      |> Enum.map(&render_node(&1, ctx))
      |> B.concat()
      |> B.trim()
    end

    # Document root: just recurse
    defp render_node(%MDEx.Document{nodes: nodes}, ctx), do: render_nodes(nodes, ctx)

    # Inline formatting: wrap children in the entity
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

    # Inline code: entity over the literal text (no escaping needed)
    defp render_node(%MDEx.Code{literal: literal}, _ctx) do
      B.code(literal)
    end

    # Fenced code block: pre entity with optional language
    defp render_node(%MDEx.CodeBlock{info: info, literal: literal}, _ctx) do
      lang = info && String.trim(info)
      lang = if lang == "", do: nil, else: lang
      # Strip trailing newline from literal (comrak always adds one)
      text = String.trim_trailing(literal, "\n")
      B.concat([B.pre(text, lang), B.text("\n\n")])
    end

    # Link: text_link entity
    defp render_node(%MDEx.Link{url: url, nodes: nodes}, ctx) do
      {inner_text, inner_entities} = render_nodes(nodes, ctx)

      inner_text
      |> B.text_link(url)
      |> then(fn {t, [link_entity]} ->
        # Preserve nested entities (bold/italic inside link text)
        {t, [link_entity | inner_entities]}
      end)
    end

    # Image: render alt text only (Telegram can't display images in text)
    defp render_node(%MDEx.Image{nodes: nodes}, ctx) do
      render_nodes(nodes, ctx)
    end

    # Headings: render as bold with surrounding newlines
    defp render_node(%MDEx.Heading{nodes: nodes}, ctx) do
      inner = render_nodes(nodes, ctx)
      B.concat([B.wrap("bold", inner), B.text("\n\n")])
    end

    # Paragraph: add blank line after
    defp render_node(%MDEx.Paragraph{nodes: nodes}, ctx) do
      rendered = render_nodes(nodes, ctx)
      B.concat([rendered, "\n\n"])
    end

    # Blockquote: either a blockquote entity or indented plain text
    defp render_node(%MDEx.BlockQuote{nodes: nodes}, %{skip_blockquotes: true} = ctx) do
      # Indent with 2 spaces per line instead of entity
      # Because the user asked to skip them
      {inner_text, inner_entities} = nodes |> render_nodes(ctx) |> B.trim()

      lines = String.split(inner_text, "\n")
      indent = "  "

      # Build indented text with 2 spaces per line
      indented_lines = Enum.map(lines, &(indent <> &1))
      indented = Enum.join(indented_lines, "\n")

      # Adjust each entity's offset based on which line it appears on
      adjusted_entities =
        Enum.map(inner_entities, fn entity ->
          # Calculate which line this entity starts on
          line_num = count_newlines_before(inner_text, entity.offset)
          # Add 2 spaces for each line including the current one
          extra_offset = (line_num + 1) * 2
          %{entity | offset: entity.offset + extra_offset}
        end)

      {indented <> "\n", adjusted_entities}
    end

    defp render_node(%MDEx.BlockQuote{nodes: nodes}, ctx) do
      inner = render_nodes(nodes, ctx)
      {inner_text, _} = inner
      trimmed = String.trim_trailing(inner_text, "\n")
      inner_trimmed = {trimmed, elem(inner, 1)}
      B.concat([B.blockquote(inner_trimmed), B.text("\n\n")])
    end

    # Lists
    defp render_node(%MDEx.List{list_type: list_type, start: start, nodes: nodes}, ctx) do
      child_ctx = %{ctx | list_type: list_type, list_depth: ctx.list_depth + 1}

      items =
        nodes
        |> Enum.with_index(start || 1)
        |> Enum.map(fn {item, idx} -> render_list_item(item, idx, child_ctx) end)
        |> B.concat()

      # Add blank line after top-level lists
      if ctx.list_depth == 0 do
        B.concat([items, B.text("\n")])
      else
        items
      end
    end

    defp render_node(%MDEx.ListItem{} = item, ctx) do
      # ListItem outside a List context: render children directly
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

    # Table: render as a code block (pre entity), plain text only
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

    # Thematic break (---): dashes
    defp render_node(%MDEx.ThematicBreak{}, _ctx), do: B.text("---\n")

    # Soft and hard breaks
    defp render_node(%MDEx.SoftBreak{}, _ctx), do: B.text("\n")
    defp render_node(%MDEx.LineBreak{}, _ctx), do: B.text("\n")

    # Plain text: no escaping needed (not MarkdownV2)
    defp render_node(%MDEx.Text{literal: literal}, _ctx), do: B.text(literal)

    # Raw HTML: strip tags, plain text
    defp render_node(%MDEx.HtmlInline{literal: literal}, _ctx), do: B.text(strip_html_tags(literal))

    defp render_node(%MDEx.HtmlBlock{literal: literal}, _ctx), do: B.text(strip_html_tags(literal))

    # Unknown nodes with children: recurse gracefully
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

      # Separate nested lists from inline content to handle newlines properly
      {inline_nodes, nested_lists} =
        Enum.split_with(nodes, fn
          %MDEx.List{} -> false
          _ -> true
        end)

      # Render inline content (paragraphs, formatting, etc.)
      inline_content =
        inline_nodes
        |> Enum.map(fn
          %MDEx.Paragraph{nodes: children} -> render_nodes(children, ctx)
          child -> render_node(child, ctx)
        end)
        |> B.concat()

      {inline_text, inline_entities} = inline_content
      trimmed = String.trim(inline_text)
      offset = B.utf16_length(prefix_str)
      adjusted_entities = B.offset_entities(inline_entities, offset)

      item_line = prefix_str <> trimmed <> "\n"

      # Render nested lists after the item line with proper newlines
      if nested_lists == [] do
        {item_line, adjusted_entities}
      else
        nested_content =
          nested_lists
          |> Enum.map(&render_node(&1, ctx))
          |> B.concat()

        {nested_text, nested_entities} = nested_content
        total_offset = B.utf16_length(item_line)
        adjusted_nested = B.offset_entities(nested_entities, total_offset)

        {item_line <> nested_text, adjusted_entities ++ adjusted_nested}
      end
    end

    defp render_list_item(node, _idx, ctx), do: render_node(node, ctx)

    # ---------------------------------------------------------------------------
    # Plain-text extraction (for table cells: no entities)
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

    # Count newlines before a UTF-16 offset position
    defp count_newlines_before(text, utf16_offset) do
      # Convert UTF-16 offset to byte offset for string slicing
      text_before = B.slice_utf16(text, 0, utf16_offset)

      text_before
      |> String.graphemes()
      |> Enum.count(&(&1 == "\n"))
    end

    # ---------------------------------------------------------------------------
    # Entity tree building (for from_entities)
    # ---------------------------------------------------------------------------

    # Converts flat entities into a nested tree structure
    defp build_entity_tree(text, entities) do
      # Sort entities by offset (asc), then by length (desc) for proper nesting
      sorted =
        entities
        |> Enum.reject(fn e -> e.length <= 0 end)
        |> Enum.sort_by(fn e -> {e.offset, -e.length} end)

      # Validate no partial overlaps (entities must be fully nested or disjoint)
      validate_entity_nesting!(sorted)

      text_len = B.utf16_length(text)
      build_tree_range(text, sorted, 0, text_len)
    end

    # Validates that entities are properly nested (no partial overlaps)
    defp validate_entity_nesting!(entities) do
      Enum.reduce(entities, [], fn entity, stack ->
        entity_end = entity.offset + entity.length
        # Pop entities from stack that end before or at the start of this entity
        stack = Enum.reject(stack, fn {_parent, parent_end} -> parent_end <= entity.offset end)

        # Check remaining stack for partial overlaps
        check_partial_overlap!(entity, entity_end, stack)

        # Add current entity to stack
        [{entity, entity_end} | stack]
      end)
    end

    # Check if the current entity partially overlaps with any entity in the stack
    defp check_partial_overlap!(entity, entity_end, stack) do
      Enum.each(stack, fn {parent, parent_end} ->
        # If current entity extends beyond parent's end, it's a partial overlap
        if entity_end > parent_end do
          raise ArgumentError,
                "Partial entity overlap detected: entity at offset #{parent.offset} (type: #{parent.type}, length: #{parent.length}) " <>
                  "and entity at offset #{entity.offset} (type: #{entity.type}, length: #{entity.length}) overlap but neither fully contains the other. " <>
                  "Entities must be either fully nested or completely disjoint."
        end
      end)
    end

    # Build tree for a specific UTF-16 range
    defp build_tree_range(text, entities, range_start, range_end) do
      # Find entities that start exactly at range_start
      {starting_here, rest} = Enum.split_while(entities, fn e -> e.offset == range_start end)

      case starting_here do
        [] ->
          # No entity at this position, check for gap or done
          handle_no_entity_at_position(text, rest, range_start, range_end)

        [entity | also_at_start] ->
          # Entity starts here
          entity_end = min(entity.offset + entity.length, range_end)

          # Find children: entities fully contained within this entity
          # Include both entities that also started here (also_at_start) and entities from rest
          all_potential_children = also_at_start ++ rest

          children =
            Enum.filter(all_potential_children, fn e ->
              e.offset >= entity.offset and e.offset + e.length <= entity_end
            end)

          # Build entity node
          entity_children = build_tree_range(text, children, entity.offset, entity_end)
          entity_node = {:entity, entity, entity_children}

          # Exclude children from rest for continuation
          rest_after = Enum.reject(rest, fn e -> e in children end)

          # Continue after this entity
          [entity_node | build_tree_range(text, rest_after, entity_end, range_end)]
      end
    end

    # Handle the case where no entity starts at the current position
    defp handle_no_entity_at_position(text, rest, range_start, range_end) do
      case Enum.find(rest, fn e -> e.offset < range_end end) do
        nil ->
          # No more entities in this range
          if range_start < range_end do
            gap_text = B.slice_utf16(text, range_start, range_end - range_start)
            [{:text, gap_text}]
          else
            []
          end

        next_entity ->
          # Gap before next entity
          gap_text = B.slice_utf16(text, range_start, next_entity.offset - range_start)
          [{:text, gap_text} | build_tree_range(text, rest, next_entity.offset, range_end)]
      end
    end

    # ---------------------------------------------------------------------------
    # CommonMark rendering (direct string rendering, not MDEx AST)
    # ---------------------------------------------------------------------------

    defp tree_to_commonmark(tree) do
      Enum.map_join(tree, &tree_node_to_commonmark/1)
    end

    defp tree_node_to_commonmark({:text, text}) do
      # In CommonMark, only backslashes and backticks in certain contexts need escaping
      # For simplicity, we'll escape the most common special chars
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("[", "\\[")
      |> String.replace("]", "\\]")
      |> String.replace("<", "\\<")
      |> String.replace(">", "\\>")
    end

    defp tree_node_to_commonmark({:entity, entity, children}) do
      commonmark_format_entity(entity.type, entity, children)
    end

    # Simple inline formatting
    defp commonmark_format_entity("bold", _entity, children), do: "**#{render_children_commonmark(children)}**"
    defp commonmark_format_entity("italic", _entity, children), do: "*#{render_children_commonmark(children)}*"
    defp commonmark_format_entity("underline", _entity, children), do: "__#{render_children_commonmark(children)}__"
    defp commonmark_format_entity("strikethrough", _entity, children), do: "~~#{render_children_commonmark(children)}~~"
    defp commonmark_format_entity("spoiler", _entity, children), do: "||#{render_children_commonmark(children)}||"
    defp commonmark_format_entity("code", _entity, children), do: "`#{get_entity_text(children)}`"

    # Code blocks with language
    defp commonmark_format_entity("pre", entity, children) do
      lang = entity.language || ""
      text = get_entity_text(children)
      "```#{lang}\n#{text}\n```"
    end

    # Links
    defp commonmark_format_entity("text_link", entity, children) do
      text = render_children_commonmark(children)

      if url = entity.url do
        "[#{text}](#{url})"
      else
        text
      end
    end

    defp commonmark_format_entity("url", _entity, children) do
      text = render_children_commonmark(children)
      "[#{text}](#{text})"
    end

    defp commonmark_format_entity("text_mention", entity, children) do
      "[#{render_children_commonmark(children)}](tg://user?id=#{entity.user.id})"
    end

    # Blockquotes
    defp commonmark_format_entity(type, _entity, children) when type in ["blockquote", "expandable_blockquote"] do
      children
      |> render_children_commonmark()
      |> String.split("\n")
      |> Enum.map_join("\n", &"> #{&1}")
    end

    # Default: render children as-is
    defp commonmark_format_entity(_, _entity, children), do: render_children_commonmark(children)

    defp render_children_commonmark(children) do
      Enum.map_join(children, &tree_node_to_commonmark/1)
    end

    # Extract plain text from tree nodes (for code/pre entities)
    defp get_entity_text(children) do
      Enum.map_join(children, fn
        {:text, text} -> text
        {:entity, _entity, nested} -> get_entity_text(nested)
      end)
    end

    # ---------------------------------------------------------------------------
    # Telegram MarkdownV2 rendering
    # ---------------------------------------------------------------------------
    # Telegram MarkdownV2 rendering
    # ---------------------------------------------------------------------------

    defp tree_to_markdown_v2(tree) do
      Enum.map_join(tree, &tree_node_to_markdown_v2/1)
    end

    defp tree_node_to_markdown_v2({:text, text}) do
      escape_markdown_v2(text)
    end

    defp tree_node_to_markdown_v2({:entity, entity, children}) do
      markdown_v2_format_entity(entity.type, entity, children)
    end

    # Simple inline formatting
    defp markdown_v2_format_entity("bold", _entity, children), do: "*#{render_children_v2(children)}*"
    defp markdown_v2_format_entity("italic", _entity, children), do: "_#{render_children_v2(children)}_"
    defp markdown_v2_format_entity("underline", _entity, children), do: "__#{render_children_v2(children)}__"
    defp markdown_v2_format_entity("strikethrough", _entity, children), do: "~#{render_children_v2(children)}~"
    defp markdown_v2_format_entity("spoiler", _entity, children), do: "||#{render_children_v2(children)}||"

    defp markdown_v2_format_entity("code", _entity, children),
      do: "`#{escape_markdown_v2_code(get_entity_text(children))}`"

    # Code blocks with language
    defp markdown_v2_format_entity("pre", entity, children) do
      lang = entity.language || ""
      text = escape_markdown_v2_code(get_entity_text(children))
      "```#{lang}\n#{text}\n```"
    end

    # Links
    defp markdown_v2_format_entity("text_link", entity, children) do
      text = render_children_v2(children)

      if url = entity.url do
        "[#{text}](#{escape_markdown_v2_url(url)})"
      else
        text
      end
    end

    defp markdown_v2_format_entity("url", _entity, children) do
      url = render_children_v2(children)
      "[#{url}](#{url})"
    end

    defp markdown_v2_format_entity("text_mention", entity, children) do
      "[#{render_children_v2(children)}](tg://user?id=#{entity.user.id})"
    end

    defp markdown_v2_format_entity("custom_emoji", entity, children) do
      "[#{render_children_v2(children)}](tg://emoji?id=#{entity.custom_emoji_id})"
    end

    # Date/time
    defp markdown_v2_format_entity("date_time", entity, children) do
      url = "tg://time?unix=#{entity.unix_time}"
      url = if entity.date_time_format, do: "#{url}&format=#{entity.date_time_format}", else: url
      "[#{render_children_v2(children)}](#{url})"
    end

    # Blockquotes
    defp markdown_v2_format_entity("blockquote", _entity, children) do
      children
      |> render_children_v2()
      |> String.split("\n")
      |> Enum.map_join("\n", &">#{&1}")
    end

    defp markdown_v2_format_entity("expandable_blockquote", _entity, children) do
      inner = render_children_v2(children)
      lines = String.split(inner, "\n")

      case lines do
        [] -> "**>"
        [single] -> "**>#{single}||"
        multiple -> format_expandable_lines(multiple)
      end
    end

    # Auto-detected types: render as plain text
    defp markdown_v2_format_entity(type, _entity, children)
         when type in ["mention", "hashtag", "cashtag", "bot_command", "url", "email", "phone_number"] do
      render_children_v2(children)
    end

    # Default: render children as-is
    defp markdown_v2_format_entity(_, _entity, children), do: render_children_v2(children)

    defp format_expandable_lines([first | rest_with_last]) do
      {middle, [last]} = Enum.split(rest_with_last, -1)
      Enum.join(["**>#{first}"] ++ Enum.map(middle, &">#{&1}") ++ [">#{last}||"], "\n")
    end

    defp render_children_v2(children) do
      Enum.map_join(children, &tree_node_to_markdown_v2/1)
    end

    # Escape special characters for MarkdownV2 (general text)
    defp escape_markdown_v2(text) do
      # Must escape: _ * [ ] ( ) ~ ` > # + - = | { } . ! \
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("_", "\\_")
      |> String.replace("*", "\\*")
      |> String.replace("[", "\\[")
      |> String.replace("]", "\\]")
      |> String.replace("(", "\\(")
      |> String.replace(")", "\\)")
      |> String.replace("~", "\\~")
      |> String.replace("`", "\\`")
      |> String.replace(">", "\\>")
      |> String.replace("#", "\\#")
      |> String.replace("+", "\\+")
      |> String.replace("-", "\\-")
      |> String.replace("=", "\\=")
      |> String.replace("|", "\\|")
      |> String.replace("{", "\\{")
      |> String.replace("}", "\\}")
      |> String.replace(".", "\\.")
      |> String.replace("!", "\\!")
    end

    # Escape for code/pre entities (only ` and \)
    defp escape_markdown_v2_code(text) do
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("`", "\\`")
    end

    # Escape for URL part of links (only ) and \ and ()
    defp escape_markdown_v2_url(text) do
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("(", "\\(")
      |> String.replace(")", "\\)")
    end
  end
end
