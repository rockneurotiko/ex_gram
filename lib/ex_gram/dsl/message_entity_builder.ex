defmodule ExGram.Dsl.MessageEntityBuilder do
  @moduledoc """
  Composable builder for Telegram `ExGram.Model.MessageEntity` formatted messages.

  Instead of constructing MarkdownV2 strings with escape sequences, this module
  produces `{plain_text, [%ExGram.Model.MessageEntity{}]}` tuples. The plain text
  carries no formatting syntax; all formatting is expressed via entity annotations
  with UTF-16 offsets and lengths.

  ## Core concept

  Every builder function returns a `{text, entities}` tuple (`t:t/0`). Caller code
  builds up message content by creating these tuples and then composing them
  with `concat/1` or `join/2`. Offsets in the entities are always relative to
  the beginning of the text in that specific tuple; `concat/1` automatically
  adjusts offsets as tuples are combined.

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
  Compute the number of UTF-16 code units in the given string.
  
  This value is suitable for MessageEntity `offset` and `length` fields as required by Telegram.
  """
  @spec utf16_length(String.t()) :: non_neg_integer()
  def utf16_length(str) when is_binary(str) do
    str
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> byte_size()
    |> div(2)
  end

  # ---------------------------------------------------------------------------
  # Leaf builders - produce a single-entity tuple
  # ---------------------------------------------------------------------------

  
  
  @doc """
Creates a plain text builder tuple containing the given string with no message entities.

The returned value is a two-element tuple: the original string and an empty list of `MessageEntity`s (i.e., `{text, []}`).
"""
@spec text(String.t()) :: t()
def text(str) when is_binary(str), do: {str, []}
  @doc """
Creates a plain text tuple representing unformatted text.

Converts non-binary inputs via `to_string/1` and returns `{text, []}` (no message entities).
"""
@spec text(any()) :: t()
def text(str), do: text(to_string(str))

  
  
  @doc """
Determines whether a message tuple contains no text and no entities.
"""
@spec empty?(t()) :: boolean()
def empty?({"", []}), do: true
  @doc """
Checks whether a message builder tuple represents an empty message.

Returns `true` when the value is the empty tuple `{"", []}`, `false` otherwise.
"""
@spec empty?(t() | any()) :: boolean()
def empty?(_), do: false

  
  
  @doc """
An empty text/entity tuple representing no content.
"""
@spec empty() :: t()
def empty, do: {"", []}

  
  
  @doc """
  Wraps the given text in a Telegram "bold" message entity, producing a {text, entities} tuple.
  """
  @spec bold(String.t()) :: t()
  def bold(str) when is_binary(str) do
    wrap_inline(str, "bold")
  end

  @doc """
Returns the given value wrapped as bold text after converting it to a string.

Converts non-binary inputs with `to_string/1` before building the bold entity.

## Parameters

  - `str`: Value to be converted to text and wrapped as bold.

@returns `{text, entities}` where `entities` contains a single `MessageEntity` of type `"bold"` that spans the `text`.
"""
@spec bold(any()) :: t()
def bold(str), do: bold(to_string(str))

  
  
  @doc """
  Wraps the given text in an `italic` MessageEntity.
  
  Returns a `{text, entities}` tuple where `text` is the original string and `entities`
  contains a single `MessageEntity` of type `"italic"` spanning the entire text.
  """
  @spec italic(String.t()) :: t()
  def italic(str) when is_binary(str) do
    wrap_inline(str, "italic")
  end

  @doc """
Creates an italicized piece of message text.

Accepts any value implementing `String.Chars` (non-binary inputs are converted with `to_string/1`).

## Returns

  - A `{text, [MessageEntity]}` tuple where `text` is the input string and the `entities` list contains a single `italic` MessageEntity that spans the entire text.
"""
@spec italic(String.Chars.t()) :: t()
def italic(str), do: italic(to_string(str))

  
  
  @doc """
  Wraps the given text in a `strikethrough` MessageEntity.
  
  The returned value is a `{text, entities}` tuple where `text` is the original string
  and `entities` contains a single MessageEntity of type `"strikethrough"` covering the whole text.
  """
  @spec strikethrough(String.t()) :: t()
  def strikethrough(str) when is_binary(str) do
    wrap_inline(str, "strikethrough")
  end

  @doc """
Wraps the given text in a `strikethrough` MessageEntity.

The input is converted to a string before wrapping.

@returns A `{text, entities}` tuple where the entire returned text is annotated with a `strikethrough` entity.
"""
@spec strikethrough(String.Chars.t()) :: t()
def strikethrough(str), do: strikethrough(to_string(str))

  
  
  @doc """
  Wraps the given string in an underline message entity.
  
  Produces a {text, entities} tuple where the single MessageEntity has type "underline" and spans the entire provided text.
  """
  @spec underline(String.t()) :: t()
  def underline(str) when is_binary(str) do
    wrap_inline(str, "underline")
  end

  @doc """
Wraps the given value as underlined text.

Accepts any value convertible to a string via `to_string/1` and produces a `{text, entities}` tuple where the text is the converted string and the entities list contains a single `underline` MessageEntity spanning the entire text.

## Parameters

  - str: any value that will be converted to a string with `to_string/1`.

"""
@spec underline(term()) :: t()
def underline(str), do: underline(to_string(str))

  
  
  @doc """
  Wraps the given text in a `spoiler` MessageEntity so the entire text is marked as a spoiler.
  
  The returned value is a `{text, [MessageEntity]}` tuple where the entity covers the full UTF-16 length of the text.
  """
  @spec spoiler(String.t()) :: t()
  def spoiler(str) when is_binary(str) do
    wrap_inline(str, "spoiler")
  end

  @doc """
Wraps the given text in a `spoiler` MessageEntity.

Non-binary inputs are converted to a string using `to_string/1`.
"""
@spec spoiler(any()) :: t()
def spoiler(str), do: spoiler(to_string(str))

  
  
  @doc """
  Wraps the given text in an inline `code` MessageEntity.
  
  Returns a `{text, entities}` tuple where the single entity is a `code` entity spanning the text.
  """
  @spec code(String.t()) :: t()
  def code(str) when is_binary(str) do
    wrap_inline(str, "code")
  end

  @doc """
Creates an inline `code` message entity for the given value.

Converts non-binary inputs using `to_string/1` before building the entity.

## Parameters

  - value: Any value whose string representation will be used as the entity text.

## Examples

    iex> MessageEntityBuilder.code("x = 1")
    {"x = 1", [%MessageEntity{type: "code", offset: 0, length: 6}]}

"""
@spec code(any()) :: t()
def code(str), do: code(to_string(str))

  
  
  @doc """
Wraps the given text in a preformatted (code) block MessageEntity.

The returned tuple contains the original text and a single `"pre"` MessageEntity that spans the entire text. If `language` is provided, it will be added to the entity's extra fields as the language hint.
  
## Parameters

  - language: Optional programming language hint to attach to the `"pre"` entity (e.g., "elixir", "python"). Pass `nil` to omit.

"""
@spec pre(String.t(), String.t() | nil) :: t()
def pre(str, language \\ nil)

  @doc """
  Wraps the given text in a `pre` MessageEntity, optionally specifying a language.
  
  ## Parameters
  
    - language: Language identifier (for syntax highlighting), e.g. `"elixir"`. If `nil`, the `language` field is omitted.
  
  ## Returns
  
    - `{text, [MessageEntity]}` where the single entity is of type `"pre"` spanning the entire text and includes a `language` field when provided.
  """
  @spec pre(String.t(), String.t() | nil) :: t()
  def pre(str, language) when is_binary(str) do
    wrap_inline(str, "pre", language: language)
  end

  @doc """
Wraps the given value as a `pre` message entity, optionally specifying a language for syntax highlighting.

## Parameters

  - str: Value to be used as the preformatted text; it will be converted to a string via `to_string/1`.
  - language: Optional language identifier used for syntax highlighting (or `nil` to omit).

## Returns

A `{text, entities}` tuple where `text` is the input converted to a string and `entities` contains a single `pre` `MessageEntity` that spans the entire text and includes the `language` when provided.
"""
@spec pre(any(), String.t() | nil) :: t()
def pre(str, language), do: pre(to_string(str), language)

  
  
  @doc """
  Wraps the given text in a "text_link" MessageEntity that references the provided URL.
  
  ## Parameters
  
    - str: Display text for the link.
    - url: Destination URL the link should open.
  
  """
  @spec text_link(String.t(), String.t()) :: t()
  def text_link(str, url) when is_binary(str) and is_binary(url) do
    wrap_inline(str, "text_link", url: url)
  end

  
  
  @doc """
  Create a text-mention MessageEntity that references the given User.
  
  Returns a tuple of the original text and a single "text_mention" entity which links the text to the provided User (useful for users without usernames).
  """
  @spec text_mention(String.t(), User.t()) :: t()
  def text_mention(str, %User{} = user) when is_binary(str) do
    wrap_inline(str, "text_mention", user: user)
  end

  
  
  @doc """
  Wraps the given text in a "custom_emoji" MessageEntity using the specified custom emoji identifier.
  
  ## Parameters
  
    - str: Text to annotate.
    - custom_emoji_id: Telegram custom emoji identifier to attach to the entity.
  
  ## Returns
  
    - `t()` where the text is `str` and the entities list contains a single `custom_emoji` entity spanning the entire text with `custom_emoji_id`.
  """
  @spec custom_emoji(String.t(), String.t()) :: t()
  def custom_emoji(str, custom_emoji_id) when is_binary(str) and is_binary(custom_emoji_id) do
    wrap_inline(str, "custom_emoji", custom_emoji_id: custom_emoji_id)
  end

  
  
  @doc """
  Creates a `date_time` message entity that spans the given text.
  
  The entity includes a required `unix_time` field and, if provided, a `date_time_format` field to control how the timestamp is interpreted/displayed.
  
  ## Parameters
  
    - str: The text to be covered by the `date_time` entity.
    - unix_time: Unix timestamp (integer) to include as the `unix_time` field.
    - date_time_format: Optional format string to include as the `date_time_format` field.
  
  ## Returns
  
  A `t()` tuple where the plain text is `str` and the entities list contains a single `date_time` MessageEntity with the provided fields.
  """
  @spec date_time(String.t(), integer(), String.t() | nil) :: t()
  def date_time(str, unix_time, date_time_format \\ nil) when is_binary(str) and is_integer(unix_time) do
    extra = [unix_time: unix_time]
    extra = if date_time_format, do: [{:date_time_format, date_time_format} | extra], else: extra
    wrap_inline(str, "date_time", extra)
  end

  
  
  @doc """
  Wraps the given text or entity in a blockquote MessageEntity.
  
  Accepts a plain string or an existing `{text, entities}` tuple and returns a `{text, entities}` tuple where an outer `blockquote` entity spans the entire resulting text.
  """
  @spec blockquote(String.t() | t()) :: t()
  def blockquote(inner_entity) do
    wrap("blockquote", inner_entity)
  end

  
  
  @doc """
  Wraps the given content in an outer `expandable_blockquote` MessageEntity.
  
  Accepts either a raw string or an existing `{text, entities}` tuple; returns a `{text, entities}` tuple where the original content is enclosed by a single `expandable_blockquote` entity and entity offsets are adjusted accordingly.
  """
  @spec expandable_blockquote(String.t() | t()) :: t()
  def expandable_blockquote(inner_entity) do
    wrap("expandable_blockquote", inner_entity)
  end

  # ---------------------------------------------------------------------------
  # Auto-detected entity type helpers
  # ---------------------------------------------------------------------------

  
  
  @doc """
Wraps the given text as a Telegram `mention` MessageEntity (e.g., "@username").
"""
@spec mention(String.t()) :: t()
def mention(str) when is_binary(str), do: wrap_inline(str, "mention")
  @doc """
Creates a mention message entity for the given text.

Converts non-binary inputs via `to_string/1` and returns a `{text, entities}` tuple whose single entity has type `"mention"` and spans the provided text.
"""
@spec mention(String.Chars.t()) :: t()
def mention(str), do: mention(to_string(str))

  
  
  @doc """
Wraps the given text in a "hashtag" MessageEntity (e.g., "#elixir").

Returns a `{text, entities}` tuple where `entities` contains a single `hashtag` entity covering the entire text.
"""
@spec hashtag(String.t()) :: t()
def hashtag(str) when is_binary(str), do: wrap_inline(str, "hashtag")
  @doc """
Creates a hashtag-formatted `{text, entities}` tuple from the given input.

Non-binary inputs are converted with `to_string/1` before building the entity.

## Parameters

  - str: Value to be used as the hashtag text; any value will be converted to a string.

## Returns

  - `{text, entities}` where `entities` contains a single `hashtag` MessageEntity spanning the entire returned `text`.
"""
@spec hashtag(any()) :: t()
def hashtag(str), do: hashtag(to_string(str))

  
  
  @doc """
Wraps the given text as a "cashtag" MessageEntity (for examples like "$USD").
"""
@spec cashtag(String.t()) :: t()
def cashtag(str) when is_binary(str), do: wrap_inline(str, "cashtag")
  @doc """
Builds a `cashtag` inline entity from the given value.

Converts non-binary input to a string and wraps that string in a single `cashtag` MessageEntity covering the entire text.

## Parameters

  - value: Any term that will be converted to a string via `to_string/1`.

## Returns

A `{text, [MessageEntity]}` tuple where `text` is the string representation of `value` and the entities list contains one `cashtag` entity spanning the whole text.
"""
@spec cashtag(any()) :: t()
def cashtag(str), do: cashtag(to_string(str))

  
  
  @doc """
Wraps the given text as a Telegram "bot_command" MessageEntity (for commands like "/start@bot").

## Parameters

  - str: Text to mark as a bot command.
"""
@spec bot_command(String.t()) :: t()
def bot_command(str) when is_binary(str), do: wrap_inline(str, "bot_command")
  @doc """
Creates a bot command message entity for the given input.

Converts the input to a string (via `to_string/1`) and returns a `{text, entities}` tuple where the text is the command and `entities` contains a single `bot_command` MessageEntity spanning the entire text.

## Parameters

  - str: Any value implement­ing `String.Chars` (will be converted with `to_string/1`).

"""
@spec bot_command(String.Chars.t()) :: t()
def bot_command(str), do: bot_command(to_string(str))

  
  
  @doc """
Wraps the provided text in a Telegram `url` MessageEntity, making it a clickable URL in the message.
"""
@spec url(String.t()) :: t()
def url(str) when is_binary(str), do: wrap_inline(str, "url")
  @doc """
Wraps the given value as a `url` message entity using its string representation.

Converts non-binary inputs with `to_string/1` before building the entity.
Returns a `{text, [MessageEntity]}` tuple where the single `url` entity spans the entire resulting text.
"""
@spec url(term()) :: t()
def url(str), do: url(to_string(str))

  
  
  @doc """
Creates an "email" MessageEntity for the given text.

The returned value is a `{text, [MessageEntity]}` tuple where `text` is the provided string
and a single `"email"` entity spans the entire text.
"""
@spec email(String.t()) :: t()
def email(str) when is_binary(str), do: wrap_inline(str, "email")
  @doc """
Builds an `email` inline MessageEntity for the given text.

Converts non-binary inputs using `to_string/1` before building the entity.

## Parameters

  - str: Value convertible to a string that will be used as the entity text.

@returns `t()` representing the text wrapped in an `email` MessageEntity.
"""
@spec email(String.Chars.t()) :: t()
def email(str), do: email(to_string(str))

  
  
  @doc """
Wraps the given text in a Telegram "phone_number" message entity.

Returns a {text, entities} tuple where a single `MessageEntity` of type
"phone_number" spans the entire provided string.
"""
@spec phone_number(String.t()) :: t()
def phone_number(str) when is_binary(str), do: wrap_inline(str, "phone_number")
  @doc """
Wraps the given text in a `phone_number` MessageEntity.

Accepts any value; non-binary inputs are converted with `to_string/1`. Produces a `{text, entities}` tuple where `text` is the resulting string and `entities` contains a single `phone_number` entity that spans the entire text.
"""
@spec phone_number(term()) :: t()
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
  
  
  @doc """
Joins a list of message-builder tuples into a single `{text, entities}` tuple.

Filters out empty entries, inserts `separator` (treated as plain text with no entities) between remaining parts, and concatenates texts while adjusting entity offsets so they remain correct for the resulting UTF-16-indexed text.

## Parameters

  - list: List of message-builder values (`{text, entities}`) or values convertible to text.
  - separator: String inserted between non-empty parts; it is treated as plain text and will not produce entities.

## Returns

  - A `{text, entities}` tuple representing the concatenated text and adjusted entities.
"""
@spec join([t()]) :: t()
@spec join([t()], String.t()) :: t()
def join(list, separator \\ " ")
  @doc """
Concatenates a list of text/entity tuples (or raw strings) using a separator string.

When given an empty list, returns the empty text/entity tuple. The separator is treated as plain text (contains no entities) and is interposed between non-empty entries; empty entries are omitted.
"""
@spec join([t() | String.t()], String.t()) :: t()
def join([], _separator), do: empty()

  @doc """
  Concatenates a list of message-entity tuples, inserting a plain-text separator between non-empty entries.
  
  Filters out empty entries, interposes the separator as plain text (the separator will not produce entities), and returns a single `{text, entities}` tuple with offsets adjusted.
  ## Parameters
  
    - tuples: a list of builder tuples (`{text, [MessageEntity]}`) to join.
    - separator: a binary inserted between entries as plain text; it will not carry any entities.
  
  @returns A `{text, entities}` tuple representing the concatenated result.
  """
  @spec join([t()], String.t()) :: t()
  def join(tuples, separator) when is_list(tuples) and is_binary(separator) do
    tuples
    |> Enum.reject(&empty?/1)
    |> Enum.intersperse(text(separator))
    |> concat()
  end

  
  
  @doc """
Removes leading whitespace from a `{text, entities}` tuple and adjusts entities to the new text.

Shifts entity offsets left by the number of UTF-16 code units removed. Entities fully contained in the trimmed region are dropped. Entities that partially overlap the trim boundary are rebased to offset 0 and their length is reduced to the remaining portion that lies after the trim. If a binary is provided, it is treated as plain text with no entities.
"""
@spec trim_leading(t() | String.t()) :: t()
def trim_leading(message)

  @doc """
  Removes leading whitespace from the text and adjusts message entities to the trimmed window.
  
  The function trims whitespace from the start of the text and clips/rebases any entities so their offsets and lengths refer to the resulting string. Offsets and lengths are maintained in UTF-16 code units for Telegram compatibility.
  """
  @spec trim_leading(t()) :: t()
  def trim_leading({text, entities}) do
    trimmed = String.trim_leading(text)
    lead = utf16_length(text) - utf16_length(trimmed)
    total = utf16_length(text)
    {trimmed, clip_entities_in_window(entities, lead, total)}
  end

  @doc """
Removes leading whitespace from the text and adjusts entities to match the new positions.

If given a plain string it is first converted to the builder tuple form. Entities that overlap the trimmed region are clipped and rebased; entities entirely within the trimmed region are dropped.
"""
@spec trim_leading(String.t() | t()) :: t()
def trim_leading(text), do: trim_leading(text(text))

  
  
  @doc """
  Removes leading characters that appear in `chars_to_trim` from a `{text, entities}` tuple.
  
  Adjusts entity offsets and lengths so entities are clipped and rebased to the trimmed text. `chars_to_trim` is a string of characters to remove from the start of the text.
  """
  @spec trim_leading(t() | String.t(), String.t()) :: t()
  def trim_leading({text, entities}, chars_to_trim) do
    lead = count_leading_utf16(text, chars_to_trim)
    total = utf16_length(text)
    sliced_text = slice_utf16(text, lead, total - lead)
    {sliced_text, clip_entities_in_window(entities, lead, total)}
  end

  @doc """
Removes the specified leading characters from a text (or text+entities) and adjusts entities to the resulting window.

Trims any sequence of characters from the start that appear in `chars_to_trim` (counted in UTF-16 units), slices the underlying text accordingly, and clips/rebases any entities that overlap the new start so offsets and lengths remain correct.

## Parameters

  - text: A raw string or a `{text, entities}` tuple to trim.
  - chars_to_trim: A string of characters to remove from the start of `text`.

## Examples

    iex> MessageEntityBuilder.trim_leading("  hello", " ")
    {"hello", []}

    iex> MessageEntityBuilder.trim_leading({ "  bold", [%MessageEntity{type: "bold", offset: 2, length: 4}] }, " ")
    {"bold", [%MessageEntity{type: "bold", offset: 0, length: 4}]}

"""
@spec trim_leading(t() | String.t(), String.t()) :: t()
def trim_leading(text, chars_to_trim), do: trim_leading(text(text), chars_to_trim)

  
  
  @doc """
Removes trailing whitespace from a message tuple or plain string.

If given a plain string, it is treated as the equivalent `{text, []}` tuple.
Entities that extend past the new end are clipped so their offsets and lengths
fit within the trimmed text; entities that lie entirely within the removed
trailing region are dropped. All offset/length adjustments are computed using
UTF-16 code units.
"""
@spec trim_trailing(t() | String.t()) :: t()
def trim_trailing(message)

  @doc """
  Remove trailing whitespace from the text and adjust entities to the shortened text.
  
  Entities that extend beyond the new end are clipped and their offsets/lengths are adjusted to fit within the window [0, new_end), where `new_end` is the UTF-16 length of the trimmed text.
  """
  @spec trim_trailing(t()) :: t()
  def trim_trailing({text, entities}) do
    trimmed = String.trim_trailing(text)
    new_end = utf16_length(trimmed)
    {trimmed, clip_entities_in_window(entities, 0, new_end)}
  end

  @doc """
Removes trailing whitespace from the builder or raw text and adjusts entity offsets and lengths to match the trimmed result.

If given a raw string it is first converted into a `{text, entities}` builder. Entities that extend into the trimmed region are clipped or dropped so remaining entities align with the new text.
"""
@spec trim_trailing(String.t() | t()) :: t()
def trim_trailing(text), do: trim_trailing(text(text))

  
  
  @doc """
  Removes trailing characters present in `chars_to_trim` from a text value and adjusts entity offsets and lengths accordingly.
  
  ## Parameters
  
    - value: A `{text, entities}` tuple or a plain string. If a plain string is provided, it is treated as `{text, []}`.
    - chars_to_trim: A string whose characters will be removed from the end of `text`.
  
  ## Returns
  
    - A `{text, entities}` tuple where trailing characters from `chars_to_trim` are removed and entities are clipped/rebased to the resulting UTF-16 window.
  """
  @spec trim_trailing(t() | String.t(), String.t()) :: t()
  def trim_trailing({text, entities}, chars_to_trim) do
    trail = count_trailing_utf16(text, chars_to_trim)
    total = utf16_length(text)
    new_end = total - trail
    sliced_text = slice_utf16(text, 0, new_end)
    {sliced_text, clip_entities_in_window(entities, 0, new_end)}
  end

  @doc """
Removes trailing occurrences of the given characters from the input text and adjusts/clips any entities to the resulting text window.

Parameters

  - text: Binary or value convertible to a string; treated as plain text and converted via `to_string/1`.
  - chars_to_trim: String containing characters to remove from the end of the text.

Returns the trimmed `{text, entities}` tuple with entity offsets and lengths rebased to the new text.
"""
@spec trim_trailing(String.t() | any, String.t()) :: t()
def trim_trailing(text, chars_to_trim), do: trim_trailing(text(text), chars_to_trim)

  
  
  @doc """
Removes leading and trailing whitespace from a message builder or plain string.

Adjusts entity offsets and lengths to match the trimmed text: entities entirely within trimmed regions are dropped, and entities that partially overlap trimmed regions are clipped and rebased to start at the new beginning.
"""
@spec trim(t() | String.t()) :: t()
def trim(message)

  @doc """
  Removes leading and trailing whitespace from a text/entity tuple and adjusts entities to the trimmed window.
  
  The returned tuple contains the trimmed UTF-8 string and the list of `MessageEntity` structs that overlap the new text range; entities are clipped to the remaining window and their offsets are rebased to the start of the trimmed text.
  """
  @spec trim(t()) :: t()
  def trim({text, entities}) do
    trimmed = String.trim(text)
    # Calculate UTF-16 offsets for leading and trailing trim
    lead_trimmed = String.trim_leading(text)
    lead = utf16_length(text) - utf16_length(lead_trimmed)
    new_end = lead + utf16_length(trimmed)
    {trimmed, clip_entities_in_window(entities, lead, new_end)}
  end

  @doc """
Removes leading and trailing Unicode whitespace from the given text and adjusts entities to the trimmed window.

Accepts either a raw string or a `{text, entities}` builder tuple. Entities that fall outside the trimmed region are dropped; entities that partially overlap the new boundaries are clipped and rebased so their offsets/lengths match the trimmed text.
"""
@spec trim(String.t() | t()) :: t()
def trim(text), do: trim(text(text))

  
  
  @doc """
  Removes specified leading and trailing characters from a `{text, entities}` tuple.
  
  Trims characters listed in `chars_to_trim` from both ends (like `String.trim/2`), adjusts entity offsets and lengths to the resulting window, drops entities wholly within trimmed regions, and clips entities that partially overlap the trimmed boundaries.
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

  @doc """
Removes the specified leading and trailing characters from the input and adjusts entities to the new text window.

If given a raw string it is first converted to the builder tuple form. Trimming is performed in UTF-16 code units (surrogate-safe); any entities that fall outside the trimmed window are dropped, and entities that partially overlap the window are clipped and rebased so their offsets and lengths match the resulting text.

## Parameters

  - text: a builder tuple `{text, entities}` or a raw string.
  - chars_to_trim: a string containing characters to remove from both ends of `text`.

## Examples

    iex> trim("  hello  ", " ")
    {"hello", []}

"""
@spec trim(t() | String.t(), String.t()) :: t()
def trim(text, chars_to_trim), do: trim(text(text), chars_to_trim)

  
  
  @doc """
Wraps an inner text/entity value in an outer MessageEntity of the given type.

The outer entity covers the entire inner text and is returned as a {text, entities} tuple
where the outer entity is added around any existing entities. Any additional
fields required by the entity type (for example `url` for `text_link` or
`language` for `pre`) can be supplied via `extra_fields`.

## Parameters

  - entity_type: The MessageEntity type name (for example `"bold"`, `"text_link"`, `"pre"`).
  - inner_entity: Either a raw string or an existing `{text, entities}` tuple to be wrapped.
  - extra_fields: Keyword list of extra fields to include on the outer entity.

## Returns

  - A `{text, entities}` tuple with the outer MessageEntity spanning the entire text.
"""
@spec wrap(String.t(), String.t() | t(), keyword()) :: t()
def wrap(entity_type, inner_entity, extra_fields \\ [])

  @doc """
  Wraps the given text and its entities with an outer MessageEntity of the specified type.
  
  The outer entity will span the entire inner text (offset 0, length measured in UTF-16 code units) and include any provided extra fields. The returned value is the same text with the new outer entity prepended to the entity list.
  
  ## Parameters
  
    - entity_type: The type for the outer MessageEntity (e.g., `:bold`, `:italic`, `"pre"`, etc.).
    - {inner_text, inner_entities}: A tuple of the plain UTF-8 text and its list of existing MessageEntity structs.
    - extra_fields: Keyword list of additional fields to set on the outer MessageEntity (merged with `type`, `offset`, and `length`).
  
  ## Returns
  
    - A `{text, entities}` tuple where `text` is unchanged and `entities` has the new outer MessageEntity prepended.
  """
  @spec wrap(atom() | String.t(), {String.t(), [entity()]}, keyword()) :: {String.t(), [entity()]}
  def wrap(entity_type, {inner_text, inner_entities}, extra_fields) do
    attrs = Keyword.merge(extra_fields, type: entity_type, offset: 0, length: utf16_length(inner_text))
    outer = struct!(MessageEntity, attrs)

    {inner_text, [outer | inner_entities]}
  end

  @doc """
  Wraps the given plain text in an outer MessageEntity of the specified type, attaching any provided extra fields to that outer entity.
  
  @param entity_type The MessageEntity type (e.g., :bold, "pre", "text_link").
  @param inner_text The plain text to wrap; converted to a builder tuple before wrapping.
  @param extra_fields Map of additional fields to include on the outer entity (e.g., %{language: "elixir"} or %{url: "..."}).
  
  @spec wrap(atom() | String.t(), String.t(), map()) :: t()
  """
  def wrap(entity_type, inner_text, extra_fields) do
    wrap(entity_type, text(inner_text), extra_fields)
  end

  
  
  @doc """
Adjusts all MessageEntity offsets by the given UTF-16 unit offset.

Increases each entity's `offset` field by `offset`, preserving other entity fields.

## Parameters

  - offset: Number of UTF-16 code units to add to each entity's offset.

## Returns

  - A list of entities with updated `offset` values.
"""
@spec offset_entities([entity()], non_neg_integer()) :: [entity()]
def offset_entities(entities, 0), do: entities

  @doc """
  Shift each MessageEntity's offset forward by the given UTF-16 unit offset.
  
  ## Parameters
  
    - entities: List of `%MessageEntity{}` to be shifted.
    - offset: Number of UTF-16 code units to add to each entity's `offset`. Must be greater than 0.
  
  ## Returns
  
    - List of `%MessageEntity{}` with each entity's `offset` increased by `offset`.
  """
  @spec offset_entities([entity()], integer()) :: [entity()]
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

  @doc """
  Truncates a message to at most `max_size` UTF-16 code units and appends `truncate_text` when truncation occurs.
  
  If the message's UTF-16 length is greater than `max_size`, returns a new `{text, entities}` tuple where the text is cut so that, after appending `truncate_text`, the total UTF-16 length does not exceed `max_size`. Entity offsets and lengths are adjusted or dropped so they remain valid within the truncated text.
  """
  @spec truncate(t(), non_neg_integer(), String.t()) :: t()
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

  @doc """
Truncates a message to at most `max_size` UTF-16 code units, appending `truncate_text` if truncation occurs.

Returns a `{text, entities}` tuple where the plain text length (measured in UTF-16 code units) does not exceed `max_size`. `truncate_text` is inserted as plain text at the end of the resulting message and counts toward the `max_size` limit. Entities are clipped or rebased to fit the resulting window; entities that no longer overlap the kept window are dropped. If `truncate_text` alone consumes the entire `max_size`, the original text may be discarded and only `truncate_text` (with no entities) returned.

## Parameters

  - message: a `{text, entities}` tuple or a value convertible to text (will be converted via `text/1`).
  - max_size: maximum allowed length in UTF-16 code units.
  - truncate_text: plain string appended when truncation happens (counts toward `max_size`).

"""
@spec truncate(t() | String.t(), non_neg_integer(), String.t()) :: t()
def truncate(message, max_size, truncate_text), do: truncate(text(message), max_size, truncate_text)

  @doc """
  Splits a `{text, entities}` tuple into a list of tuples, each with a UTF-16
  length of at most `max_length`.

  The split respects entity boundaries: if an entity would span a split point it
  is moved entirely to the next part. The only exception is when the entity alone
  is larger than `max_length` - in that case it is split at the limit (unavoidable).

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

  @doc """
Splits a plain string into parts whose UTF-16 lengths do not exceed `max_length`, returning a list of `{text, entities}` tuples.

`max_length` is measured in UTF-16 code units; each returned part's text has UTF-16 length less than or equal to `max_length`. Since this overload accepts a plain string, returned parts will have empty entity lists.
"""
@spec split(String.t(), non_neg_integer()) :: [t()]
def split(text, max_length), do: split(text(text), max_length)

  
  
  @doc """
Extracts a substring defined by UTF-16 code unit positions.

The slice begins at UTF-16 index `start` and spans `length` UTF-16 code units. Surrogate pairs are preserved so no high/low surrogate is split; if the requested window extends beyond the string, the available range is returned.

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

      # Find entities that start before `raw_end` but end after it - they span
      # the candidate cut point and must be kept whole (pushed to next part).
      spanning =
        Enum.filter(entities, fn e ->
          e.offset < raw_end and e.offset + e.length > raw_end
        end)

      cut = calculate_cut_point(spanning, current, raw_end, remaining, max_length)

      part_text = slice_utf16(text, current, cut - current)
      # Recalculate the actual cut based on what slice_utf16 produced
      # (it may have backed up to avoid splitting a surrogate pair).
      actual_cut = current + utf16_length(part_text)

      # If slice_utf16 backed up from a surrogate pair producing "",
      # force progress by taking the next full Unicode scalar.
      {part_text, actual_cut} =
        if actual_cut == current do
          # Take the next full codepoint starting at `current` UTF-16 offset.
          # A surrogate pair (the only case where backing up to empty happens)
          # is exactly 2 UTF-16 units. Requesting 2 units will capture it.
          next_cp = slice_utf16(text, current, 2)
          {next_cp, current + utf16_length(next_cp)}
        else
          {part_text, actual_cut}
        end

      part_entities = clip_entities_in_window(entities, current, actual_cut)
      part = {part_text, part_entities}

      do_split(text, entities, max_length, actual_cut, [part | acc])
    end
  end

  # Calculate the optimal cut point considering spanning entities.
  defp calculate_cut_point(spanning, current, raw_end, remaining, max_length) do
    if spanning == [] do
      # No spanning entity - cut cleanly at raw_end (or end of text).
      min(raw_end, current + remaining)
    else
      # Move cut to just before the earliest spanning entity's start -
      # unless that entity is larger than max_length (failsafe).
      earliest_start = spanning |> Enum.map(& &1.offset) |> Enum.min()
      entity_len = spanning |> Enum.map(&(&1.offset + &1.length)) |> Enum.max()
      entity_size = entity_len - earliest_start

      if entity_size >= max_length do
        # Entity alone exceeds max_length - forced split at raw_end.
        min(raw_end, current + remaining)
      else
        # Back the cut up to just before this entity, but never behind
        # `current` (that would cause an infinite loop for edge cases).
        max(earliest_start, current + 1)
      end
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
          # We are cutting inside a surrogate pair - step back 2 bytes.
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
