defmodule ExGram.MarkdownTest do
  use ExUnit.Case, async: true

  alias ExGram.Dsl.MessageEntityBuilder, as: B
  alias ExGram.Markdown

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
end
