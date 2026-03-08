defmodule ExGram.MarkdownTest do
  use ExUnit.Case, async: true

  alias ExGram.Dsl.MessageEntityBuilder, as: B
  alias ExGram.Markdown
  alias ExGram.Model.MessageEntity
  alias ExGram.Model.User

  describe "to_entities/2" do
    test "plain text has no entities" do
      {text, entities} = Markdown.to_entities("hello world", [])
      assert String.trim(text) == "hello world"
      assert entities == []
    end

    test "bold markdown produces bold entity" do
      {text, entities} = Markdown.to_entities("**bold**", [])
      assert text =~ "bold"
      assert Enum.any?(entities, &(&1.type == "bold"))
    end

    test "italic markdown produces italic entity" do
      {text, entities} = Markdown.to_entities("*italic*", [])
      assert text =~ "italic"
      assert Enum.any?(entities, &(&1.type == "italic"))
    end

    test "inline code produces code entity" do
      {text, entities} = Markdown.to_entities("`code`", [])
      assert text =~ "code"
      assert Enum.any?(entities, &(&1.type == "code"))
    end

    test "fenced code block produces pre entity" do
      markdown = "```elixir\nIO.puts(:ok)\n```"
      {text, entities} = Markdown.to_entities(markdown, [])
      assert text =~ "IO.puts"
      assert Enum.any?(entities, &(&1.type == "pre"))
    end

    test "blockquote produces blockquote or expandable_blockquote entity" do
      markdown = "> some quoted text"
      {text, entities} = Markdown.to_entities(markdown, [])
      assert text =~ "some quoted text"
      assert Enum.any?(entities, &(&1.type in ["blockquote", "expandable_blockquote"]))
    end

    test "nested bold in italic" do
      {text, entities} = Markdown.to_entities("_italic **bold** italic_", [])
      assert text =~ "bold"
      assert Enum.any?(entities, &(&1.type == "italic"))
    end

    test "entity offsets are non-negative" do
      {_text, entities} = Markdown.to_entities("# Heading\n**bold** text", [])

      Enum.each(entities, fn e ->
        assert e.offset >= 0
        assert e.length > 0
      end)
    end

    test "entity offsets + lengths do not exceed text length in UTF-16 units" do
      {text, entities} = Markdown.to_entities("hello **world** bye", [])
      total = B.utf16_length(text)

      Enum.each(entities, fn e ->
        assert e.offset + e.length <= total
      end)
    end

    test "spoiler markdown produces spoiler entity" do
      {text, entities} = Markdown.to_entities("||spoiler text||", [])
      assert text =~ "spoiler text"
      assert Enum.any?(entities, &(&1.type == "spoiler"))

      spoiler = Enum.find(entities, &(&1.type == "spoiler"))
      assert spoiler.offset >= 0
      assert spoiler.length > 0
    end

    test "nested formatting inside spoiler" do
      {text, entities} = Markdown.to_entities("||**bold spoiler**||", [])
      assert text =~ "bold spoiler"
      assert Enum.any?(entities, &(&1.type == "spoiler"))
      assert Enum.any?(entities, &(&1.type == "bold"))

      # Bold entity should be nested inside spoiler
      spoiler = Enum.find(entities, &(&1.type == "spoiler"))
      bold = Enum.find(entities, &(&1.type == "bold"))
      assert spoiler.offset == 0
      assert bold.offset == 0
    end

    test "autolinks produce text_link entities" do
      {text, entities} = Markdown.to_entities("Visit https://example.com for info", [])
      assert text =~ "https://example.com"
      assert Enum.any?(entities, &(&1.type == "text_link"))

      link = Enum.find(entities, &(&1.type == "text_link"))
      assert link.url == "https://example.com"
    end

    test "angle-bracket autolinks produce text_link entities" do
      {text, entities} = Markdown.to_entities("Visit <https://example.com> for info", [])
      assert text =~ "https://example.com"
      assert Enum.any?(entities, &(&1.type == "text_link"))

      link = Enum.find(entities, &(&1.type == "text_link"))
      assert link.url == "https://example.com"
    end
  end

  describe "from_entities/2 - CommonMark format" do
    alias B, as: B

    test "empty text and entities" do
      assert Markdown.from_entities(B.empty(), :markdown) == ""
    end

    test "plain text with no entities" do
      input = B.text("hello world")
      result = Markdown.from_entities(input, :markdown)
      assert result == "hello world"
    end

    test "bold entity" do
      input = B.concat([B.bold("bold"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "**bold** text"
    end

    test "italic entity" do
      input = B.concat([B.italic("italic"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "*italic* text"
    end

    test "underline entity" do
      input = B.concat([B.underline("underline"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "__underline__ text"
    end

    test "strikethrough entity" do
      input = B.concat([B.strikethrough("strikethrough"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "~~strikethrough~~ text"
    end

    test "spoiler entity" do
      input = B.concat([B.spoiler("spoiler"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "||spoiler|| text"
    end

    test "code entity" do
      input = B.concat([B.code("code"), " here"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "`code` here"
    end

    test "pre entity without language" do
      input = B.pre("def hello():")
      result = Markdown.from_entities(input, :markdown)
      assert result == "```\ndef hello():\n```"
    end

    test "pre entity with language" do
      input = B.pre("def hello():", "elixir")
      result = Markdown.from_entities(input, :markdown)
      assert result == "```elixir\ndef hello():\n```"
    end

    test "text_link entity" do
      input = B.concat([B.text_link("link", "https://example.com"), " here"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "[link](https://example.com) here"
    end

    test "nested entities: bold inside italic" do
      input = B.concat([B.wrap("italic", B.concat([B.text("italic "), B.bold("bold")])), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "*italic **bold*** text"
    end

    test "nested entities: italic inside link" do
      input =
        B.concat([
          B.wrap("text_link", B.concat([B.italic("italic"), " link"]), url: "https://example.com"),
          " text"
        ])

      result = Markdown.from_entities(input, :markdown)
      assert result == "[*italic* link](https://example.com) text"
    end

    test "adjacent entities" do
      input = B.concat([B.bold("bold"), " ", B.italic("italic"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "**bold** *italic* text"
    end

    test "auto-detected entities render as plain text" do
      input = B.concat([B.mention("@username"), " here"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "@username here"
    end

    test "UTF-16 handling with emoji" do
      # Emoji "👍" is 2 UTF-16 code units
      input = B.concat([B.bold("👍"), " text"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "**👍** text"
    end

    test "blockquote entity" do
      input = B.blockquote("quoted text!")
      result = Markdown.from_entities(input, :markdown)
      assert result == "> quoted text!"
    end

    test "text_mention entity" do
      user = %User{id: 123_456}
      input = B.concat([B.text_mention("John", user), " here"])
      result = Markdown.from_entities(input, :markdown)
      assert result == "[John](tg://user?id=123456) here"
    end

    test "complex message with multiple nested entities" do
      input =
        B.concat([
          B.bold("Welcome"),
          " to ",
          B.italic("ExGram"),
          "! ",
          B.text_link("Click here", "https://example.com"),
          " to learn more about ",
          B.wrap("bold", B.concat([B.text("nested "), B.italic("formatting")])),
          ". ",
          B.code("Code.works!"),
          " and ",
          B.strikethrough("deprecated"),
          " features."
        ])

      result = Markdown.from_entities(input, :markdown)

      expected =
        "**Welcome** to *ExGram*! [Click here](https://example.com) to learn more about " <>
          "**nested *formatting***. `Code.works!` and ~~deprecated~~ features."

      assert result == expected
    end

    test "round-trip: simple bold" do
      markdown = "**bold** text"
      {text, entities} = Markdown.to_entities(markdown)
      result = Markdown.from_entities({text, entities}, :markdown)
      assert String.trim(result) == String.trim(markdown)
    end

    test "round-trip: italic" do
      markdown = "*italic* text"
      {text, entities} = Markdown.to_entities(markdown)
      result = Markdown.from_entities({text, entities}, :markdown)
      assert String.trim(result) == String.trim(markdown)
    end

    test "round-trip: code" do
      markdown = "`code` text"
      {text, entities} = Markdown.to_entities(markdown)
      result = Markdown.from_entities({text, entities}, :markdown)
      assert String.trim(result) == String.trim(markdown)
    end

    test "round-trip: link" do
      markdown = "[link text](https://example.com)"
      {text, entities} = Markdown.to_entities(markdown)
      result = Markdown.from_entities({text, entities}, :markdown)
      assert String.trim(result) == String.trim(markdown)
    end

    test "round-trip: complex markdown document" do
      markdown = """
      # ExGram Documentation

      **ExGram** is a *powerful* Telegram bot framework for Elixir.

      ## Features

      - **Easy to use** API
      - *Flexible* routing
      - ~~Complex~~ Simple middleware
      - `Pattern matching` support

      Check out the [official docs](https://hexdocs.pm/ex_gram) for more info!

      ```elixir
      defmodule MyBot do
        use ExGram.Bot
      end
      ```

      > Important: Make sure to configure your bot token!
      """

      {text, entities} = Markdown.to_entities(markdown)
      result = Markdown.from_entities({text, entities}, :markdown)

      assert result ==
               String.trim("""
               **ExGram Documentation**

               **ExGram** is a *powerful* Telegram bot framework for Elixir.

               **Features**

               • **Easy to use** API
               • *Flexible* routing
               • ~~Complex~~ Simple middleware
               • `Pattern matching` support

               Check out the [official docs](https://hexdocs.pm/ex_gram) for more info!

               ```elixir
               defmodule MyBot do
                 use ExGram.Bot
               end
               ```

               > Important: Make sure to configure your bot token!
               """)
    end
  end

  describe "from_entities/2 - Telegram MarkdownV2 format" do
    alias B, as: B

    test "empty text and entities" do
      assert Markdown.from_entities(B.empty(), :markdown_v2) == ""
    end

    test "plain text with no entities" do
      input = B.text("hello world")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "hello world"
    end

    test "bold entity" do
      input = B.concat([B.bold("bold"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "*bold* text"
    end

    test "italic entity" do
      input = B.concat([B.italic("italic"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "_italic_ text"
    end

    test "underline entity" do
      input = B.concat([B.underline("underline"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "__underline__ text"
    end

    test "strikethrough entity" do
      input = B.concat([B.strikethrough("strikethrough"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "~strikethrough~ text"
    end

    test "spoiler entity" do
      input = B.concat([B.spoiler("spoiler"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "||spoiler|| text"
    end

    test "code entity" do
      input = B.concat([B.code("code"), " here"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "`code` here"
    end

    test "code entity with backticks inside" do
      input = B.concat([B.code("a`b`c"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "`a\\`b\\`c` text"
    end

    test "pre entity without language" do
      input = B.pre("def hello():")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "```\ndef hello():\n```"
    end

    test "pre entity with language" do
      input = B.pre("def hello():", "elixir")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "```elixir\ndef hello():\n```"
    end

    test "text_link entity" do
      input = B.concat([B.text_link("link", "https://example.com"), " here"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[link](https://example.com) here"
    end

    test "text_link with special characters in URL" do
      input = B.concat([B.text_link("link", "https://example.com/path(with)parens"), " here"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[link](https://example.com/path\\(with\\)parens) here"
    end

    test "nested entities: bold inside italic" do
      input = B.concat([B.wrap("italic", B.concat([B.text("italic "), B.bold("bold")])), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "_italic *bold*_ text"
    end

    test "nested entities: italic inside link" do
      input =
        B.concat([
          B.wrap("text_link", B.concat([B.italic("italic"), " link"]), url: "https://example.com"),
          " text"
        ])

      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[_italic_ link](https://example.com) text"
    end

    test "adjacent entities" do
      input = B.concat([B.bold("bold"), " ", B.italic("italic"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "*bold* _italic_ text"
    end

    test "auto-detected entities render as plain text" do
      input = B.concat([B.mention("@username"), " here"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "@username here"
    end

    test "escapes special characters in plain text" do
      input = B.text("test_with*special[chars]")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "test\\_with\\*special\\[chars\\]"
    end

    test "UTF-16 handling with emoji" do
      # Emoji "👍" is 2 UTF-16 code units
      input = B.concat([B.bold("👍"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "*👍* text"
    end

    test "blockquote entity" do
      input = B.blockquote("quoted text!")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == ">quoted text\\!"
    end

    test "expandable_blockquote entity" do
      input = B.expandable_blockquote("quoted text!")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "**>quoted text\\!||"
    end

    test "text_mention entity" do
      user = %User{id: 123_456}
      input = B.concat([B.text_mention("John", user), " here"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[John](tg://user?id=123456) here"
    end

    test "custom_emoji entity" do
      input = B.concat([B.custom_emoji("👍", "5368324170671202286"), " text"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[👍](tg://emoji?id=5368324170671202286) text"
    end

    test "date_time entity" do
      input = B.concat([B.date_time("22:45", 1_647_531_900), " tomorrow"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[22:45](tg://time?unix=1647531900) tomorrow"
    end

    test "date_time entity with format" do
      input = B.concat([B.date_time("22:45", 1_647_531_900, "wDT"), " tomorrow"])
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "[22:45](tg://time?unix=1647531900&format=wDT) tomorrow"
    end

    test "complex message with all entity types" do
      user = %User{id: 123_456}

      input =
        B.concat([
          B.bold("Hello"),
          " ",
          B.text_mention("John", user),
          "\\! ",
          B.wrap(
            "italic",
            B.concat([
              B.text("This is "),
              B.wrap("underline", B.concat([B.text("nested "), B.strikethrough("complex")]))
            ])
          ),
          " ",
          B.text_link("formatting", "https://example.com/test(1)"),
          "\\. ",
          B.code("use ExGram"),
          " and ",
          B.spoiler("secret"),
          "\\!"
        ])

      result = Markdown.from_entities(input, :markdown_v2)

      expected =
        "*Hello* [John](tg://user?id=123456)\\\\\\\! _This is __nested ~complex~___ " <>
          "[formatting](https://example.com/test\\(1\\))\\\\\\\. `use ExGram` and ||secret||\\\\\\\!"

      assert result == expected
    end

    test "escaping all special characters" do
      # Test all 18 special characters that need escaping in MarkdownV2
      input = B.text("_*[]()~`>#+-=|{}.!\\")
      result = Markdown.from_entities(input, :markdown_v2)
      assert result == "\\_\\*\\[\\]\\(\\)\\~\\`\\>\\#\\+\\-\\=\\|\\{\\}\\.\\!\\\\"
    end
  end

  describe "bug fixes" do
    test "Bug #1: nested lists render with proper newlines" do
      markdown = """
      - Item 1
        - Nested 1
        - Nested 2
      - Item 2
      """

      {text, _entities} = Markdown.to_entities(markdown)

      # Each list item should be on its own line
      assert text =~ "• Item 1\n"
      assert text =~ "  • Nested 1\n"
      assert text =~ "  • Nested 2\n"
      assert text =~ "• Item 2"

      # Verify no items are joined on the same line
      refute text =~ "Item 1  • Nested"
    end

    test "Bug #2: skip_blockquotes with multi-line content preserves entity offsets" do
      markdown = "> line 1\n> **bold line 2**"
      {text, entities} = Markdown.to_entities(markdown, skip_blockquotes: true)

      # Note: Due to document-level trim, the first line loses its indent,
      # but subsequent lines keep their indentation. This is acceptable behavior.
      assert text =~ "line 1\n"
      assert text =~ "  bold line 2"

      # Bold entity should correctly point to "bold line 2"
      bold = Enum.find(entities, &(&1.type == "bold"))
      assert bold
      extracted = B.slice_utf16(text, bold.offset, bold.length)
      assert extracted == "bold line 2"
    end

    test "Bug #3: from_entities rejects partial entity overlaps" do
      text = "hello world"
      # Create partially overlapping entities (neither fully contains the other)
      entities = [
        # "hello w"
        %MessageEntity{type: "bold", offset: 0, length: 7},
        # "lo world"
        %MessageEntity{type: "italic", offset: 3, length: 8}
      ]

      assert_raise ArgumentError, ~r/Partial entity overlap detected/, fn ->
        Markdown.from_entities({text, entities}, :markdown)
      end
    end

    test "Bug #3: from_entities allows valid nested entities" do
      text = "hello world"
      # Fully nested entities (italic inside bold)
      entities = [
        %MessageEntity{type: "bold", offset: 0, length: 10},
        %MessageEntity{type: "italic", offset: 0, length: 5}
      ]

      # Should not raise
      result = Markdown.from_entities({text, entities}, :markdown)
      assert result =~ "**"
      assert result =~ "*"
    end

    test "Bug #3: from_entities allows adjacent entities" do
      text = "hello world"
      # Adjacent entities (touching but not overlapping)
      entities = [
        %MessageEntity{type: "bold", offset: 0, length: 5},
        %MessageEntity{type: "italic", offset: 5, length: 6}
      ]

      # Should not raise
      result = Markdown.from_entities({text, entities}, :markdown)
      assert result =~ "**hello**"
      assert result =~ "* world*"
    end

    test "Bug #4: from_entities handles nil URL gracefully" do
      text = "hello"

      entities = [
        %MessageEntity{type: "text_link", offset: 0, length: 5, url: nil}
      ]

      # CommonMark: should fall back to plain text
      result_md = Markdown.from_entities({text, entities}, :markdown)
      assert result_md == "hello"

      # MarkdownV2: should fall back to plain text
      result_v2 = Markdown.from_entities({text, entities}, :markdown_v2)
      assert result_v2 == "hello"
    end

    test "Bug #4: from_entities with valid URL still works" do
      text = "hello"

      entities = [
        %MessageEntity{type: "text_link", offset: 0, length: 5, url: "https://example.com"}
      ]

      result = Markdown.from_entities({text, entities}, :markdown)
      assert result == "[hello](https://example.com)"
    end
  end
end
