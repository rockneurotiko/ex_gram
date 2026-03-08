defmodule ExGram.Dsl.MessageEntityBuilderTest do
  use ExUnit.Case, async: true

  alias ExGram.Dsl.MessageEntityBuilder, as: B

  describe "utf16_length/1" do
    test "ASCII string" do
      assert B.utf16_length("hello") == 5
    end

    test "empty string" do
      assert B.utf16_length("") == 0
    end

    test "BMP characters (U+0080..U+FFFF) count as 1 UTF-16 unit each" do
      # "café" - é is U+00E9, single UTF-16 code unit
      assert B.utf16_length("café") == 4
    end

    test "emoji outside BMP (U+1F600+) counts as 2 UTF-16 units" do
      # "😀" is U+1F600 (surrogate pair in UTF-16)
      assert B.utf16_length("😀") == 2
    end

    test "string with mixed ASCII and emoji" do
      # "hi😀" = 2 ASCII + 2 for emoji = 4
      assert B.utf16_length("hi😀") == 4
    end

    test "Chinese characters (BMP, 1 unit each)" do
      # "你好" = 2 chars, each BMP
      assert B.utf16_length("你好") == 2
    end

    test "newlines count as 1" do
      assert B.utf16_length("a\nb") == 3
    end
  end

  describe "text/1" do
    test "returns {string, []} for plain text" do
      assert B.text("hello") == {"hello", []}
    end

    test "empty string" do
      assert B.text("") == {"", []}
    end
  end

  describe "bold/1" do
    test "wraps text in bold entity at offset 0" do
      {text, [entity]} = B.bold("bold!")
      assert text == "bold!"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "works with unicode (emoji, UTF-16 length)" do
      {_text, [entity]} = B.bold("hi😀")
      # hi = 2, 😀 = 2 UTF-16 units → length = 4
      assert entity.length == 4
    end
  end

  describe "italic/1" do
    test "wraps text in italic entity" do
      {text, [entity]} = B.italic("slanted")
      assert text == "slanted"
      assert entity.type == "italic"
      assert entity.offset == 0
      assert entity.length == 7
    end
  end

  describe "code/1" do
    test "wraps text in code entity" do
      {text, [entity]} = B.code("fn x -> x end")
      assert text == "fn x -> x end"
      assert entity.type == "code"
    end
  end

  describe "pre/2" do
    test "pre with no language" do
      {text, [entity]} = B.pre("IO.puts(:ok)")
      assert text == "IO.puts(:ok)"
      assert entity.type == "pre"
      assert is_nil(entity.language)
    end

    test "pre with language" do
      {text, [entity]} = B.pre("x = 1", "elixir")
      assert text == "x = 1"
      assert entity.type == "pre"
      assert entity.language == "elixir"
    end
  end

  describe "text_link/2" do
    test "creates text_link entity" do
      {text, [entity]} = B.text_link("click here", "https://example.com")
      assert text == "click here"
      assert entity.type == "text_link"
      assert entity.url == "https://example.com"
    end
  end

  describe "blockquote/1" do
    test "wraps text tuple in blockquote entity" do
      {text, [entity]} = B.blockquote(B.text("quoted text"))
      assert text == "quoted text"
      assert entity.type == "blockquote"
    end
  end

  describe "expandable_blockquote/1" do
    test "wraps text tuple in expandable_blockquote entity" do
      {text, [entity]} = B.expandable_blockquote(B.text("long output"))
      assert text == "long output"
      assert entity.type == "expandable_blockquote"
    end
  end

  describe "spoiler/1" do
    test "wraps text in spoiler entity" do
      {text, [entity]} = B.spoiler("secret")
      assert text == "secret"
      assert entity.type == "spoiler"
      assert entity.offset == 0
      assert entity.length == 6
    end

    test "works with unicode" do
      {_text, [entity]} = B.spoiler("🎁")
      # 🎁 = 2 UTF-16 units
      assert entity.length == 2
    end
  end

  describe "text_mention/2" do
    test "creates text_mention entity with user" do
      user = %ExGram.Model.User{id: 123, is_bot: false, first_name: "John"}
      {text, [entity]} = B.text_mention("John", user)
      assert text == "John"
      assert entity.type == "text_mention"
      assert entity.user == user
    end
  end

  describe "custom_emoji/2" do
    test "creates custom_emoji entity" do
      {text, [entity]} = B.custom_emoji("👍", "5368324170671202286")
      assert text == "👍"
      assert entity.type == "custom_emoji"
      assert entity.custom_emoji_id == "5368324170671202286"
    end
  end

  describe "date_time/2" do
    test "creates date_time entity with unix_time" do
      {text, [entity]} = B.date_time("2023-01-01", 1_672_531_200)
      assert text == "2023-01-01"
      assert entity.type == "date_time"
      assert entity.unix_time == 1_672_531_200
      assert entity.date_time_format == nil
    end
  end

  describe "date_time/3" do
    test "creates date_time entity with format" do
      {text, [entity]} = B.date_time("2023-01-01", 1_672_531_200, "yyyy-MM-dd")
      assert text == "2023-01-01"
      assert entity.type == "date_time"
      assert entity.unix_time == 1_672_531_200
      assert entity.date_time_format == "yyyy-MM-dd"
    end
  end

  describe "mention/1" do
    test "creates mention entity" do
      {text, [entity]} = B.mention("@username")
      assert text == "@username"
      assert entity.type == "mention"
    end
  end

  describe "hashtag/1" do
    test "creates hashtag entity" do
      {text, [entity]} = B.hashtag("#elixir")
      assert text == "#elixir"
      assert entity.type == "hashtag"
    end
  end

  describe "cashtag/1" do
    test "creates cashtag entity" do
      {text, [entity]} = B.cashtag("$USD")
      assert text == "$USD"
      assert entity.type == "cashtag"
    end
  end

  describe "bot_command/1" do
    test "creates bot_command entity" do
      {text, [entity]} = B.bot_command("/start")
      assert text == "/start"
      assert entity.type == "bot_command"
    end
  end

  describe "url/1" do
    test "creates url entity" do
      {text, [entity]} = B.url("https://example.com")
      assert text == "https://example.com"
      assert entity.type == "url"
    end
  end

  describe "email/1" do
    test "creates email entity" do
      {text, [entity]} = B.email("user@example.com")
      assert text == "user@example.com"
      assert entity.type == "email"
    end
  end

  describe "phone_number/1" do
    test "creates phone_number entity" do
      {text, [entity]} = B.phone_number("+1234567890")
      assert text == "+1234567890"
      assert entity.type == "phone_number"
    end
  end

  describe "concat/1" do
    test "concatenates two simple text tuples" do
      result = B.concat([B.text("hello "), B.text("world")])
      {text, entities} = result
      assert text == "hello world"
      assert entities == []
    end

    test "re-offsets entities from second segment" do
      {text, entities} = B.concat([B.bold("foo"), B.text(" "), B.italic("bar")])
      assert text == "foo bar"
      assert length(entities) == 2
      bold = Enum.find(entities, &(&1.type == "bold"))
      italic = Enum.find(entities, &(&1.type == "italic"))
      assert bold.offset == 0
      assert bold.length == 3
      assert italic.offset == 4
      assert italic.length == 3
    end

    test "empty list returns empty tuple" do
      assert B.concat([]) == {"", []}
    end

    test "accepts plain strings mixed with tuples" do
      {text, entities} = B.concat([B.bold("Hello"), ", ", "world", "!"])
      assert text == "Hello, world!"
      assert length(entities) == 1
      bold = hd(entities)
      assert bold.type == "bold"
      assert bold.offset == 0
      assert bold.length == 5
    end

    test "accepts only plain strings" do
      {text, entities} = B.concat(["Hello", " ", "world"])
      assert text == "Hello world"
      assert entities == []
    end

    test "plain strings do not affect entity offsets" do
      {text, entities} = B.concat(["Start ", B.bold("bold"), " end"])
      assert text == "Start bold end"
      assert length(entities) == 1
      bold = hd(entities)
      assert bold.type == "bold"
      assert bold.offset == 6
      assert bold.length == 4
    end
  end

  describe "join/1" do
    test "joins with default space separator" do
      {text, _entities} = B.join([B.text("hello"), B.text("world")])
      assert text == "hello world"
    end

    test "entities are re-offset correctly with default separator" do
      {text, entities} = B.join([B.bold("foo"), B.italic("bar"), B.code("baz")])
      assert text == "foo bar baz"
      assert length(entities) == 3

      bold = Enum.find(entities, &(&1.type == "bold"))
      italic = Enum.find(entities, &(&1.type == "italic"))
      code = Enum.find(entities, &(&1.type == "code"))

      assert bold.offset == 0
      assert bold.length == 3
      assert italic.offset == 4
      assert italic.length == 3
      assert code.offset == 8
      assert code.length == 3
    end

    test "empty list returns empty tuple" do
      assert B.join([]) == {"", []}
    end

    test "accepts plain strings mixed with tuples" do
      {text, entities} = B.join([B.bold("Hello"), "world", B.italic("!")], " ")
      assert text == "Hello world !"
      assert length(entities) == 2

      bold = Enum.find(entities, &(&1.type == "bold"))
      italic = Enum.find(entities, &(&1.type == "italic"))

      assert bold.offset == 0
      assert bold.length == 5
      assert italic.offset == 12
      assert italic.length == 1
    end

    test "accepts only plain strings with default separator" do
      {text, entities} = B.join(["one", "two", "three"])
      assert text == "one two three"
      assert entities == []
    end
  end

  describe "join/2" do
    test "joins multiple segments with separator string" do
      {text, _entities} = B.join([B.text("a"), B.text("b"), B.text("c")], ", ")
      assert text == "a, b, c"
    end

    test "entities are re-offset correctly" do
      {text, entities} = B.join([B.bold("x"), B.bold("y")], "-")
      assert text == "x-y"
      assert length(entities) == 2
      [e1, e2] = Enum.sort_by(entities, & &1.offset)
      assert e1.offset == 0
      assert e2.offset == 2
    end
  end

  describe "wrap/3" do
    test "wraps inner tuple with outer entity type" do
      {text, entities} = B.wrap("bold", B.bold("important"), [])
      assert text == "important"
      assert Enum.any?(entities, &(&1.type == "bold"))
    end

    test "wraps inner tuple with outer entity type and adds info" do
      {text, entities} = B.wrap("bold", B.bold("important"), url: "https://example.com")
      assert text == "important"
      [outer | _] = entities
      assert outer.type == "bold"
      assert outer.url == "https://example.com"
    end
  end

  describe "offset_entities/2" do
    test "shifts all entity offsets by given amount" do
      {_text, [entity]} = B.bold("hi")
      shifted = B.offset_entities([entity], 10)
      assert hd(shifted).offset == 10
    end
  end

  describe "truncate/3" do
    test "returns message unchanged when text is within limit" do
      msg = B.bold("hello")
      assert B.truncate(msg, 10) == msg
    end

    test "returns message unchanged when text length equals limit" do
      msg = B.bold("hello")
      # "hello" is 5 UTF-16 units; with default "..." suffix that's 8 total,
      # but since 5 <= 5, no truncation happens.
      assert B.truncate(msg, 5) == msg
    end

    test "truncates plain text with no entities" do
      {text, entities} = B.truncate(B.text("hello world"), 8, "...")
      # cutoff = 8 - 3 = 5 → "hello" + "..." = "hello..."
      assert text == "hello..."
      assert entities == []
    end

    test "drops entities that start at or after the cut point" do
      # "aaa bbb" - bold on "bbb" at offset 4..7
      msg = B.concat([B.text("aaa "), B.bold("bbb")])
      {text, entities} = B.truncate(msg, 6, "...")
      # cutoff = 6 - 3 = 3 → sliced text = "aaa", bold entity starts at 4 → dropped
      assert text == "aaa..."
      assert entities == []
    end

    test "trims entities that extend past the cut point" do
      # Bold over "hello world" (11 chars), truncate at 8 with "..."
      msg = B.bold("hello world")
      {text, entities} = B.truncate(msg, 8, "...")
      # cutoff = 5, sliced = "hello"
      assert text == "hello..."
      assert length(entities) == 1
      [e] = entities
      assert e.type == "bold"
      assert e.offset == 0
      assert e.length == 5
    end

    test "handles emoji (2 UTF-16 units) in sliced text" do
      # "hi😀bye" - 2 + 2 + 3 = 7 UTF-16 units; truncate at 5 with "…" (1 unit)
      msg = B.text("hi😀bye")
      {text, _} = B.truncate(msg, 5, "…")
      # cutoff = 4, slice 4 units = "hi😀"
      assert text == "hi😀…"
    end

    test "returns empty string when max_size is 0" do
      msg = B.bold("hello")
      {text, entities} = B.truncate(msg, 0, "...")
      assert text == ""
      assert entities == []
    end

    test "uses empty truncate_text when specified" do
      msg = B.bold("hello world")
      {text, entities} = B.truncate(msg, 5, "")
      assert text == "hello"
      assert [e] = entities
      assert e.length == 5
    end
  end

  describe "split/2" do
    test "returns single-element list when text fits" do
      msg = B.bold("hello")
      assert B.split(msg, 10) == [msg]
    end

    test "returns single-element list when text length equals limit" do
      msg = B.bold("hello")
      assert B.split(msg, 5) == [msg]
    end

    test "splits plain text with no entities" do
      msg = B.text("abcdef")
      parts = B.split(msg, 3)
      assert length(parts) == 2
      [{t1, []}, {t2, []}] = parts
      assert t1 == "abc"
      assert t2 == "def"
    end

    test "splits text into more than two parts" do
      msg = B.text("abcdefghi")
      parts = B.split(msg, 3)
      assert length(parts) == 3
      texts = Enum.map(parts, fn {t, _} -> t end)
      assert texts == ["abc", "def", "ghi"]
    end

    test "entity fully within first part stays in first part" do
      # "aaa bbb" - bold on "aaa" (offset 0, length 3), split at 4
      msg = B.concat([B.bold("aaa"), B.text(" bbb")])
      [part1, part2] = B.split(msg, 4)
      {t1, e1} = part1
      {t2, e2} = part2
      assert t1 == "aaa "
      assert length(e1) == 1
      assert hd(e1).type == "bold"
      assert hd(e1).offset == 0
      assert t2 == "bbb"
      assert e2 == []
    end

    test "entity spanning split boundary is moved to next part" do
      # "aaa bold" - bold on "bold" (offset 4, length 4), split at 5
      msg = B.concat([B.text("aaa "), B.bold("bold")])
      [part1, part2] = B.split(msg, 5)
      {t1, e1} = part1
      {t2, e2} = part2
      # cut is moved back to 4 (start of bold entity)
      assert t1 == "aaa "
      assert e1 == []
      assert t2 == "bold"
      assert length(e2) == 1
      assert hd(e2).type == "bold"
      assert hd(e2).offset == 0
      assert hd(e2).length == 4
    end

    test "entity larger than max_length is force-split" do
      # bold over "abcdef" (6 chars), split at 3
      msg = B.bold("abcdef")
      [part1, part2] = B.split(msg, 3)
      {t1, e1} = part1
      {t2, e2} = part2
      assert t1 == "abc"
      assert [e] = e1
      assert e.type == "bold"
      assert e.offset == 0
      assert e.length == 3
      assert t2 == "def"
      assert [e2e] = e2
      assert e2e.offset == 0
      assert e2e.length == 3
    end

    test "entity offsets in later parts are rebased to 0" do
      # "xxx bold" split at 4: part1="xxx ", part2="bold" with bold entity at offset 0
      msg = B.concat([B.text("xxx "), B.bold("bold")])
      [_part1, part2] = B.split(msg, 4)
      {_t, [e]} = part2
      assert e.offset == 0
    end

    test "handles emoji spanning split boundary" do
      # "ab😀cd" - emoji at UTF-16 offset 2, length 2; split at 3
      # cutting at 3 lands inside the emoji (offset 2+2=4 > 3 > 2=offset),
      # so slice_utf16 backs up and the first part is "ab" (2 units).
      # The second part is "😀cd" which is 4 UTF-16 units; with max_length=3
      # it is further split into "😀c" (3 units) and "d" (1 unit).
      msg = B.text("ab😀cd")
      parts = B.split(msg, 3)
      texts = Enum.map(parts, fn {t, _} -> t end)
      assert "ab" in texts
      # emoji is never split mid-codepoint
      Enum.each(texts, fn t ->
        refute String.contains?(t, <<0xD8::8>>)
      end)

      assert Enum.join(texts) == "ab😀cd"
    end

    test "splits pre entity correctly" do
      # Long code block
      code = "line1\nline2\nline3\nline4"
      msg = B.pre(code, "elixir")
      parts = B.split(msg, 12)

      # Verify all parts maintain the pre entity
      Enum.each(parts, fn {_text, entities} ->
        assert length(entities) == 1
        assert hd(entities).type == "pre"
        assert hd(entities).language == "elixir"
        assert hd(entities).offset == 0
      end)

      # Verify concatenated text equals original
      full_text = Enum.map_join(parts, fn {t, _} -> t end)
      assert full_text == code
    end

    test "splits code entity correctly" do
      # Inline code
      msg = B.code("function_with_very_long_name")
      parts = B.split(msg, 10)

      # Each part should have a code entity
      Enum.each(parts, fn {_text, entities} ->
        assert length(entities) == 1
        assert hd(entities).type == "code"
        assert hd(entities).offset == 0
      end)

      # Verify concatenated text equals original
      full_text = Enum.map_join(parts, fn {t, _} -> t end)
      assert full_text == "function_with_very_long_name"
    end
  end

  describe "trim_leading/1" do
    test "trims leading whitespace from plain text" do
      {text, entities} = B.trim_leading("  hello")
      assert text == "hello"
      assert entities == []
    end

    test "trims leading whitespace and shifts entity offsets" do
      msg = B.concat([B.text("  "), B.bold("world")])
      {text, [entity]} = B.trim_leading(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "no-op when no leading whitespace" do
      msg = B.bold("hello")
      assert B.trim_leading(msg) == msg
    end

    test "drops entities entirely in the trimmed leading region" do
      msg = B.concat([B.bold("  "), B.italic("hello")])
      {text, [entity]} = B.trim_leading(msg)
      assert text == "hello"
      assert entity.type == "italic"
      assert entity.offset == 0
    end

    test "clips entities that partially overlap the trim boundary" do
      # "  world" where bold spans entire string
      msg = B.bold("  world")
      {text, [entity]} = B.trim_leading(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "works with plain string input" do
      {text, entities} = B.trim_leading("  hello")
      assert text == "hello"
      assert entities == []
    end

    test "works with emoji (UTF-16 surrogate pairs)" do
      # "  😀hi" = 2 spaces (2) + emoji (2) + "hi" (2) = 6 UTF-16 units
      msg = B.concat([B.text("  "), B.bold("😀hi")])
      {text, [entity]} = B.trim_leading(msg)
      assert text == "😀hi"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 4
    end
  end

  describe "trim_leading/2" do
    test "trims specific characters" do
      {text, _} = B.trim_leading("---hello", "-")
      assert text == "hello"
    end

    test "trims repeated pattern" do
      {text, _} = B.trim_leading("-*-*hello", "-*")
      assert text == "hello"
    end

    test "adjusts entity offsets correctly" do
      msg = B.concat([B.text("---"), B.bold("world")])
      {text, [entity]} = B.trim_leading(msg, "-")
      assert text == "world"
      assert entity.offset == 0
    end
  end

  describe "trim_trailing/1" do
    test "trims trailing whitespace from plain text" do
      {text, entities} = B.trim_trailing("hello  ")
      assert text == "hello"
      assert entities == []
    end

    test "trims trailing whitespace and clips entity lengths" do
      msg = B.concat([B.bold("world"), B.text("  ")])
      {text, [entity]} = B.trim_trailing(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "no-op when no trailing whitespace" do
      msg = B.bold("hello")
      assert B.trim_trailing(msg) == msg
    end

    test "drops entities entirely in the trimmed trailing region" do
      msg = B.concat([B.italic("hello"), B.bold("  ")])
      {text, [entity]} = B.trim_trailing(msg)
      assert text == "hello"
      assert entity.type == "italic"
    end

    test "works with plain string input" do
      {text, entities} = B.trim_trailing("hello  ")
      assert text == "hello"
      assert entities == []
    end

    test "clips entities that partially extend into trailing region" do
      # "world  " where bold spans entire string
      msg = B.bold("world  ")
      {text, [entity]} = B.trim_trailing(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end
  end

  describe "trim_trailing/2" do
    test "trims specific characters" do
      {text, _} = B.trim_trailing("hello---", "-")
      assert text == "hello"
    end

    test "trims repeated pattern" do
      {text, _} = B.trim_trailing("hello-*-*", "-*")
      assert text == "hello"
    end

    test "adjusts entity lengths correctly" do
      msg = B.concat([B.bold("world"), B.text("---")])
      {text, [entity]} = B.trim_trailing(msg, "-")
      assert text == "world"
      assert entity.length == 5
    end
  end

  describe "trim/1" do
    test "trims both leading and trailing whitespace" do
      {text, _} = B.trim("  hello  ")
      assert text == "hello"
    end

    test "adjusts entities correctly (shift and clip)" do
      msg = B.concat([B.text("  "), B.bold("world"), B.text("  ")])
      {text, [entity]} = B.trim(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "all-whitespace string returns empty tuple" do
      {text, entities} = B.trim("   ")
      assert text == ""
      assert entities == []
    end

    test "entities fully inside trimmed regions are dropped" do
      msg = B.concat([B.bold("  "), B.italic("hi"), B.bold("  ")])
      {text, [entity]} = B.trim(msg)
      assert text == "hi"
      assert entity.type == "italic"
    end

    test "entities partially overlapping on either side are clipped" do
      # "  world  " where bold spans entire string
      msg = B.bold("  world  ")
      {text, [entity]} = B.trim(msg)
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "works with plain string input" do
      {text, _} = B.trim("  hello  ")
      assert text == "hello"
    end

    test "works with emoji (UTF-16 surrogate pairs)" do
      # "  😀hi  " = 2 spaces + emoji (2) + "hi" (2) + 2 spaces = 8 units
      msg = B.concat([B.text("  "), B.bold("😀hi"), B.text("  ")])
      {text, [entity]} = B.trim(msg)
      assert text == "😀hi"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 4
    end
  end

  describe "trim/2" do
    test "trims specific characters from both ends" do
      {text, _} = B.trim("---hello---", "-")
      assert text == "hello"
    end

    test "trims repeated pattern from both ends" do
      {text, _} = B.trim("-*-*hello-*-*", "-*")
      assert text == "hello"
    end

    test "adjusts entities correctly" do
      msg = B.concat([B.text("---"), B.bold("world"), B.text("---")])
      {text, [entity]} = B.trim(msg, "-")
      assert text == "world"
      assert entity.type == "bold"
      assert entity.offset == 0
      assert entity.length == 5
    end

    test "handles edge case where entire string is trim pattern" do
      {text, entities} = B.trim("-----", "-")
      assert text == ""
      assert entities == []
    end
  end
end
