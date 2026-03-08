defmodule ExGram.Dsl.MessageEntityBuilder do
  @moduledoc """
  Composable builder for Telegram `MessageEntity` formatted messages.

  Instead of constructing MarkdownV2 strings with escape sequences, this module
  produces `{plain_text, [%ExGram.Model.MessageEntity{}]}` tuples. The plain text
  carries no formatting syntax; all formatting is expressed via entity annotations
  with UTF-16 offsets and lengths.

  ## Core concept

  Every builder function returns a `{text, entities}` tuple. Caller code
  builds up message content by creating these tuples and then composing them
  with `concat/1` or `join/2`. Offsets in the entities are always relative to
  the beginning of the text in that specific tuple; `concat/1` takes care of
  adjusting offsets as tuples are combined.

  ## Example

      iex> alias EntityBuilder, as: B
      iex> B.concat([B.bold("Hello"), B.text(", "), B.italic("world")])
      {"Hello, world", [
        %ExGram.Model.MessageEntity{type: "bold", offset: 0, length: 5},
        %ExGram.Model.MessageEntity{type: "italic", offset: 7, length: 5}
      ]}

  """

  alias ExGram.Model.MessageEntity
  alias ExGram.Model.User

  @type entity :: %MessageEntity{}
  @type t :: {String.t(), [entity()]}

  @doc """
  Returns the number of UTF-16 code units in the given string.

  This is what Telegram expects for `MessageEntity` `offset` and `length` fields.
  """
  @spec utf16_length(String.t()) :: non_neg_integer()
  def utf16_length(str) when is_binary(str) do
    str
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> byte_size()
    |> div(2)
  end

  # ---------------------------------------------------------------------------
  # Leaf builders — produce a single-entity tuple
  # ---------------------------------------------------------------------------

  @doc "Plain text with no formatting."
  @spec text(String.t()) :: t()
  def text(str) when is_binary(str), do: {str, []}
  def text(str), do: text(to_string(str))

  @doc "Checks if a tuple is empty (i.e. has no text and no entities)."
  @spec empty?(t()) :: boolean()
  def empty?({"", []}), do: true
  def empty?(_), do: false

  @doc "Empty tuple."
  @spec empty() :: t()
  def empty, do: {"", []}

  @doc "Bold text."
  @spec bold(String.t()) :: t()
  def bold(str) when is_binary(str) do
    wrap_inline(str, "bold")
  end

  def bold(str), do: bold(to_string(str))

  @doc "Italic text."
  @spec italic(String.t()) :: t()
  def italic(str) when is_binary(str) do
    wrap_inline(str, "italic")
  end

  def italic(str), do: italic(to_string(str))

  @doc "Strikethrough text."
  @spec strikethrough(String.t()) :: t()
  def strikethrough(str) when is_binary(str) do
    wrap_inline(str, "strikethrough")
  end

  def strikethrough(str), do: strikethrough(to_string(str))

  @doc "Underline text."
  @spec underline(String.t()) :: t()
  def underline(str) when is_binary(str) do
    wrap_inline(str, "underline")
  end

  def underline(str), do: underline(to_string(str))

  @doc "Spoiler text."
  @spec spoiler(String.t()) :: t()
  def spoiler(str) when is_binary(str) do
    wrap_inline(str, "spoiler")
  end

  def spoiler(str), do: spoiler(to_string(str))

  @doc "Inline code."
  @spec code(String.t()) :: t()
  def code(str) when is_binary(str) do
    wrap_inline(str, "code")
  end

  def code(str), do: code(to_string(str))

  @doc "Code block (pre). Optionally specify a programming language."
  @spec pre(String.t(), String.t() | nil) :: t()
  def pre(str, language \\ nil)

  def pre(str, language) when is_binary(str) do
    wrap_inline(str, "pre", language: language)
  end

  def pre(str, language), do: pre(to_string(str), language)

  @doc "Clickable text link."
  @spec text_link(String.t(), String.t()) :: t()
  def text_link(str, url) when is_binary(str) and is_binary(url) do
    wrap_inline(str, "text_link", url: url)
  end

  @doc "Text mention (for users without usernames)."
  @spec text_mention(String.t(), User.t()) :: t()
  def text_mention(str, %User{} = user) when is_binary(str) do
    wrap_inline(str, "text_mention", user: user)
  end

  @doc "Custom emoji."
  @spec custom_emoji(String.t(), String.t()) :: t()
  def custom_emoji(str, custom_emoji_id) when is_binary(str) and is_binary(custom_emoji_id) do
    wrap_inline(str, "custom_emoji", custom_emoji_id: custom_emoji_id)
  end

  @doc "Date/time entity."
  @spec date_time(String.t(), integer(), String.t() | nil) :: t()
  def date_time(str, unix_time, date_time_format \\ nil) when is_binary(str) and is_integer(unix_time) do
    extra = [unix_time: unix_time]
    extra = if date_time_format, do: [{:date_time_format, date_time_format} | extra], else: extra
    wrap_inline(str, "date_time", extra)
  end

  @doc "Blockquote."
  @spec blockquote(String.t() | t()) :: t()
  def blockquote(inner_entity) do
    wrap("blockquote", inner_entity)
  end

  @doc "Expandable blockquote."
  @spec expandable_blockquote(String.t() | t()) :: t()
  def expandable_blockquote(inner_entity) do
    wrap("expandable_blockquote", inner_entity)
  end

  # ---------------------------------------------------------------------------
  # Auto-detected entity type helpers
  # ---------------------------------------------------------------------------

  @doc "Mention (@username)."
  @spec mention(String.t()) :: t()
  def mention(str) when is_binary(str), do: wrap_inline(str, "mention")
  def mention(str), do: mention(to_string(str))

  @doc "Hashtag (#hashtag)."
  @spec hashtag(String.t()) :: t()
  def hashtag(str) when is_binary(str), do: wrap_inline(str, "hashtag")
  def hashtag(str), do: hashtag(to_string(str))

  @doc "Cashtag ($USD)."
  @spec cashtag(String.t()) :: t()
  def cashtag(str) when is_binary(str), do: wrap_inline(str, "cashtag")
  def cashtag(str), do: cashtag(to_string(str))

  @doc "Bot command (/start@bot)."
  @spec bot_command(String.t()) :: t()
  def bot_command(str) when is_binary(str), do: wrap_inline(str, "bot_command")
  def bot_command(str), do: bot_command(to_string(str))

  @doc "URL (clickable URL in text)."
  @spec url(String.t()) :: t()
  def url(str) when is_binary(str), do: wrap_inline(str, "url")
  def url(str), do: url(to_string(str))

  @doc "Email address."
  @spec email(String.t()) :: t()
  def email(str) when is_binary(str), do: wrap_inline(str, "email")
  def email(str), do: email(to_string(str))

  @doc "Phone number."
  @spec phone_number(String.t()) :: t()
  def phone_number(str) when is_binary(str), do: wrap_inline(str, "phone_number")
  def phone_number(str), do: phone_number(to_string(str))

  # ---------------------------------------------------------------------------
  # Composition helpers
  # ---------------------------------------------------------------------------

  @doc """
  Concatenates a list of `{text, entities}` tuples into a single tuple.

  Entity offsets from later tuples are shifted by the cumulative UTF-16 length
  of all preceding text.
  """
  @spec concat([t() | String.t()]) :: t()
  def concat(tuples) when is_list(tuples) do
    Enum.reduce(tuples, empty(), fn
      {text, entities}, {acc_text, acc_entities} ->
        do_concat(text, entities, acc_text, acc_entities)

      entity, {acc_text, acc_entities} ->
        {text, entities} = text(entity)
        do_concat(text, entities, acc_text, acc_entities)
    end)
  end

  defp do_concat(text, entities, acc_text, acc_entities) do
    offset = utf16_length(acc_text)
    shifted = offset_entities(entities, offset)
    {acc_text <> text, acc_entities ++ shifted}
  end

  @doc """
  Joins a list of `{text, entities}` tuples with a separator string between them.

  The separator itself carries no entities.
  """
  @spec join([t()]) :: t()
  @spec join([t()], String.t()) :: t()
  def join(list, separator \\ " ")
  def join([], _separator), do: empty()

  def join(tuples, separator) when is_list(tuples) and is_binary(separator) do
    tuples
    |> Enum.reject(&empty?/1)
    |> Enum.intersperse(text(separator))
    |> concat()
  end

  @doc """
  Removes leading whitespace from a `{text, entities}` tuple.

  Works like `String.trim_leading/1`. Entity offsets are shifted back and
  entities that fall entirely within the trimmed region are dropped. Entities
  that partially overlap the trim boundary have their offset set to 0 and
  length reduced.
  """
  @spec trim_leading(t() | String.t()) :: t()
  def trim_leading(message)

  def trim_leading({text, entities}) do
    trimmed = String.trim_leading(text)
    lead = utf16_length(text) - utf16_length(trimmed)
    total = utf16_length(text)
    {trimmed, clip_entities_in_window(entities, lead, total)}
  end

  def trim_leading(text), do: trim_leading(text(text))

  @doc """
  Removes leading characters from a `{text, entities}` tuple.

  Similar to `String.trim_leading/2`, removes all leading characters that
  appear in `chars_to_trim`. Entity offsets and lengths are adjusted accordingly.
  """
  @spec trim_leading(t() | String.t(), String.t()) :: t()
  def trim_leading({text, entities}, chars_to_trim) do
    lead = count_leading_utf16(text, chars_to_trim)
    total = utf16_length(text)
    sliced_text = slice_utf16(text, lead, total - lead)
    {sliced_text, clip_entities_in_window(entities, lead, total)}
  end

  def trim_leading(text, chars_to_trim), do: trim_leading(text(text), chars_to_trim)

  @doc """
  Removes trailing whitespace from a `{text, entities}` tuple.

  Works like `String.trim_trailing/1`. Entities that extend into the trimmed
  region are clipped. Entities entirely in the trimmed region are dropped.
  """
  @spec trim_trailing(t() | String.t()) :: t()
  def trim_trailing(message)

  def trim_trailing({text, entities}) do
    trimmed = String.trim_trailing(text)
    new_end = utf16_length(trimmed)
    {trimmed, clip_entities_in_window(entities, 0, new_end)}
  end

  def trim_trailing(text), do: trim_trailing(text(text))

  @doc """
  Removes trailing characters from a `{text, entities}` tuple.

  Similar to `String.trim_trailing/2`, removes all trailing characters that
  appear in `chars_to_trim`. Entity offsets and lengths are adjusted accordingly.
  """
  @spec trim_trailing(t() | String.t(), String.t()) :: t()
  def trim_trailing({text, entities}, chars_to_trim) do
    trail = count_trailing_utf16(text, chars_to_trim)
    total = utf16_length(text)
    new_end = total - trail
    sliced_text = slice_utf16(text, 0, new_end)
    {sliced_text, clip_entities_in_window(entities, 0, new_end)}
  end

  def trim_trailing(text, chars_to_trim), do: trim_trailing(text(text), chars_to_trim)

  @doc """
  Removes leading and trailing whitespace from a `{text, entities}` tuple.

  Works like `String.trim/1`. Entity offsets and lengths are adjusted to
  reflect the trimmed text. Entities fully within trimmed regions are dropped;
  entities partially overlapping are clipped.
  """
  @spec trim(t() | String.t()) :: t()
  def trim(message)

  def trim({text, entities}) do
    trimmed = String.trim(text)
    # Calculate UTF-16 offsets for leading and trailing trim
    lead_trimmed = String.trim_leading(text)
    lead = utf16_length(text) - utf16_length(lead_trimmed)
    new_end = lead + utf16_length(trimmed)
    {trimmed, clip_entities_in_window(entities, lead, new_end)}
  end

  def trim(text), do: trim(text(text))

  @doc """
  Removes leading and trailing characters from a `{text, entities}` tuple.

  Similar to `String.trim/2`, removes all leading and trailing characters that
  appear in `chars_to_trim`. Entity offsets and lengths are adjusted to reflect
  the trimmed text. Entities fully within trimmed regions are dropped; entities
  partially overlapping are clipped.
  """
  @spec trim(t() | String.t(), String.t()) :: t()
  def trim({text, entities}, chars_to_trim) do
    lead = count_leading_utf16(text, chars_to_trim)
    trail = count_trailing_utf16(text, chars_to_trim)
    total = utf16_length(text)
    new_end = max(total - trail, lead)
    sliced_text = slice_utf16(text, lead, new_end - lead)
    {sliced_text, clip_entities_in_window(entities, lead, new_end)}
  end

  def trim(text, chars_to_trim), do: trim(text(text), chars_to_trim)

  @doc """
  Wraps an existing `{text, entities}` tuple in an outer entity of the given type.

  The outer entity spans the entire inner text. Any extra fields (e.g. `url` for
  `text_link` or `language` for `pre`) can be provided via `extra_fields`.
  """
  @spec wrap(String.t(), String.t() | t(), keyword()) :: t()
  def wrap(entity_type, inner_entity, extra_fields \\ [])

  def wrap(entity_type, {inner_text, inner_entities}, extra_fields) do
    attrs = Keyword.merge(extra_fields, type: entity_type, offset: 0, length: utf16_length(inner_text))
    outer = struct!(MessageEntity, attrs)

    {inner_text, [outer | inner_entities]}
  end

  def wrap(entity_type, inner_text, extra_fields) do
    wrap(entity_type, text(inner_text), extra_fields)
  end

  @doc """
  Shifts all entity offsets by the given UTF-16 offset.

  Used internally by `concat/1` and by callers that prepend text before
  an already-built `{text, entities}` tuple.
  """
  @spec offset_entities([entity()], non_neg_integer()) :: [entity()]
  def offset_entities(entities, 0), do: entities

  def offset_entities(entities, offset) when is_integer(offset) and offset > 0 do
    Enum.map(entities, fn entity ->
      %{entity | offset: entity.offset + offset}
    end)
  end

  @doc """
  Truncates a `{text, entities}` tuple so the total UTF-16 length does not exceed
  `max_size`.

  When the text is longer than `max_size`, it is cut and `truncate_text` is
  appended. `truncate_text` is always treated as plain text (no entity). The
  `max_size` limit is *inclusive* of the `truncate_text` suffix, so the returned
  text will never exceed `max_size` UTF-16 code units.

  Entities are adjusted as follows:
  - Entities that start at or after the cut point are dropped.
  - Entities that extend past the cut point are trimmed to end exactly at the
    cut point.

  If `max_size` is smaller than or equal to the length of `truncate_text` itself,
  only the first `max_size` UTF-16 units of `truncate_text` are kept and no
  original text is preserved.

  Returns the tuple unchanged when no truncation is needed.
  """
  @spec truncate(t() | String.t(), non_neg_integer(), String.t()) :: t()
  def truncate(message, max_size, truncate_text \\ "...")

  def truncate({text, entities} = message, max_size, truncate_text) do
    text_len = utf16_length(text)

    if text_len <= max_size do
      message
    else
      suffix_len = utf16_length(truncate_text)
      cutoff = max(max_size - suffix_len, 0)
      sliced = slice_utf16(text, 0, cutoff)
      adjusted = clip_entities(entities, cutoff)
      {sliced <> slice_utf16(truncate_text, 0, max_size - cutoff), adjusted}
    end
  end

  def truncate(message, max_size, truncate_text), do: truncate(text(message), max_size, truncate_text)

  @doc """
  Splits a `{text, entities}` tuple into a list of tuples, each with a UTF-16
  length of at most `max_length`.

  The split respects entity boundaries: if an entity would span a split point it
  is moved entirely to the next part. The only exception is when the entity alone
  is larger than `max_length` — in that case it is split at the limit (unavoidable).

  Returns a list with a single element when no splitting is needed.
  """
  @spec split(t() | String.t(), pos_integer()) :: [t()]
  def split({text, entities} = message, max_length) when is_integer(max_length) and max_length > 0 do
    total_len = utf16_length(text)

    if total_len <= max_length do
      [message]
    else
      do_split(text, entities, max_length, 0, [])
    end
  end

  def split(text, max_length), do: split(text(text), max_length)

  @doc """
  Slices a string by UTF-16 code unit position.

  Takes a string `str`, starts at UTF-16 position `start`, and extracts `length`
  UTF-16 code units. Ensures surrogate pairs are not split.

  ## Examples

      iex> slice_utf16("hello", 0, 5)
      "hello"

      iex> slice_utf16("hello world", 6, 5)
      "world"

  """
  @spec slice_utf16(String.t(), non_neg_integer(), non_neg_integer()) :: String.t()
  def slice_utf16(str, start, length), do: do_slice_utf16(str, start, length)

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Recursively build split parts.
  # `current` is the current UTF-16 start offset in the *original* text.
  defp do_split(text, entities, max_length, current, acc) do
    total_len = utf16_length(text)
    remaining = total_len - current

    if remaining <= 0 do
      Enum.reverse(acc)
    else
      raw_end = current + max_length

      # Find entities that start before `raw_end` but end after it — they span
      # the candidate cut point and must be kept whole (pushed to next part).
      spanning =
        Enum.filter(entities, fn e ->
          e.offset < raw_end and e.offset + e.length > raw_end
        end)

      cut =
        if spanning == [] do
          # No spanning entity — cut cleanly at raw_end (or end of text).
          min(raw_end, current + remaining)
        else
          # Move cut to just before the earliest spanning entity's start —
          # unless that entity is larger than max_length (failsafe).
          earliest_start = spanning |> Enum.map(& &1.offset) |> Enum.min()
          entity_len = spanning |> Enum.map(&(&1.offset + &1.length)) |> Enum.max()
          entity_size = entity_len - earliest_start

          if entity_size >= max_length do
            # Entity alone exceeds max_length — forced split at raw_end.
            min(raw_end, current + remaining)
          else
            # Back the cut up to just before this entity, but never behind
            # `current` (that would cause an infinite loop for edge cases).
            max(earliest_start, current + 1)
          end
        end

      part_text = slice_utf16(text, current, cut - current)
      # Recalculate the actual cut based on what slice_utf16 produced
      # (it may have backed up to avoid splitting a surrogate pair).
      actual_cut = current + utf16_length(part_text)
      part_entities = clip_entities_in_window(entities, current, actual_cut)
      part = {part_text, part_entities}

      do_split(text, entities, max_length, actual_cut, [part | acc])
    end
  end

  # Clip entities to a window [window_start, window_end) in the original text,
  # rebase their offsets to be relative to `window_start`.
  defp clip_entities_in_window(entities, window_start, window_end) do
    window_len = window_end - window_start

    entities
    |> Enum.filter(fn e ->
      # Keep entities that have any overlap with the window.
      e.offset < window_end and e.offset + e.length > window_start
    end)
    |> Enum.map(fn e ->
      new_offset = max(e.offset - window_start, 0)
      new_end = min(e.offset + e.length - window_start, window_len)
      %{e | offset: new_offset, length: new_end - new_offset}
    end)
    |> Enum.reject(fn e -> e.length <= 0 end)
  end

  # Drop or trim entities so none extends past `cutoff` UTF-16 units.
  defp clip_entities(entities, cutoff) do
    entities
    |> Enum.reject(fn e -> e.offset >= cutoff end)
    |> Enum.map(fn e ->
      if e.offset + e.length > cutoff do
        %{e | length: cutoff - e.offset}
      else
        e
      end
    end)
    |> Enum.reject(fn e -> e.length <= 0 end)
  end

  # Slice `str` starting at UTF-16 code-unit position `start` for `length` units.
  defp do_slice_utf16(_str, _start, length) when length <= 0, do: ""

  defp do_slice_utf16(str, start, length) do
    utf16 = :unicode.characters_to_binary(str, :utf8, {:utf16, :big})
    byte_start = start * 2
    byte_length = length * 2
    total_bytes = byte_size(utf16)

    # Clamp byte_start and compute available bytes.
    safe_start = min(byte_start, total_bytes)
    available = total_bytes - safe_start
    byte_len = min(byte_length, available)

    # Ensure we do not cut in the middle of a surrogate pair.
    # A high surrogate starts with 0xD800..0xDBFF (big-endian: first byte in 0xD8..0xDB).
    byte_len =
      if byte_len > 0 and byte_len < available do
        last_byte_pos = safe_start + byte_len - 2
        <<high, _low>> = binary_part(utf16, last_byte_pos, 2)

        if high in 0xD8..0xDB do
          # We are cutting inside a surrogate pair — step back 2 bytes.
          byte_len - 2
        else
          byte_len
        end
      else
        byte_len
      end

    slice = binary_part(utf16, safe_start, max(byte_len, 0))
    :unicode.characters_to_binary(slice, {:utf16, :big}, :utf8)
  end

  defp wrap_inline(str, type, extra \\ []) do
    attrs =
      Keyword.merge(extra,
        type: type,
        offset: 0,
        length: utf16_length(str)
      )

    entity = struct!(MessageEntity, attrs)

    {str, [entity]}
  end

  # Count leading UTF-16 code units that are in the trim set.
  defp count_leading_utf16(text, chars_to_trim) do
    trimmed = String.trim_leading(text, chars_to_trim)
    utf16_length(text) - utf16_length(trimmed)
  end

  # Count trailing UTF-16 code units that are in the trim set.
  defp count_trailing_utf16(text, chars_to_trim) do
    trimmed = String.trim_trailing(text, chars_to_trim)
    utf16_length(text) - utf16_length(trimmed)
  end
end
