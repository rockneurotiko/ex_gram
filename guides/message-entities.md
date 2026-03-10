# Formatting Messages with Entities

Telegram supports two approaches for formatting messages: **parse modes** (MarkdownV2 / HTML) and **MessageEntity annotations**. 

ExGram ships a composable DSL - `ExGram.Dsl.MessageEntityBuilder` - for the entity-based approach, and an optional `ExGram.Markdown` module that converts standard Markdown into entities using [MDEx](https://hexdocs.pm/mdex).

With entities, the plain text carries no formatting syntax. All formatting is expressed via `ExGram.Model.MessageEntity` structs with UTF-16 offsets and lengths. This means:

- **No escaping headaches** - MarkdownV2 requires escaping many special characters (`_`, `*`, `[`, `]`, `(`, `)`, `~`, `` ` ``, `>`, `#`, `+`, `-`, `=`, `|`, `{`, `}`, `.`, `!`). With entities you send plain text.
- **Longer effective messages** - Message entities doesn't consume characters from the message body, so you can fit more content within Telegram's message size limits (4096 UTF-16 characters)
- **Composable** - build messages from reusable parts and combine them freely.

## A Real Example: Entity vs MarkdownV2

Let's compare building a complex message with both approaches. Here's a status notification with multiple formatting styles:

**With MarkdownV2** (requires escaping):

```elixir
text = """
*🚀 Deployment Status*

Environment: `production`
Version: `v2\\.1\\.3`
Status: ✅ *Success*

[View logs](https://example\\.com/logs?id=123\\&env=prod)

![Deployed 5 minutes ago](tg://time?unix=1647531900&format=r)
"""

IO.puts("Length: #{B.utf16_length(text)}")
# Lenght: 210

ExGram.send_message(chat_id, text, parse_mode: "MarkdownV2")
```

**Text size: 210 characters**.
Notice the escaped dots (`\\.`) and ampersand (`\\&`) in the URL, and the escaped dots in the version number. 

**With MessageEntity**:

```elixir
alias ExGram.Dsl.MessageEntityBuilder, as: B

# We can create blocks independently
deployment_status = 
  B.join([
    B.join(["Environment:", B.code("production")]),
    B.join(["Version:", B.code("v2.1.3")]),
    B.join(["Status: ✅ ", B.bold("Success")])
  ], "\n")


{text, entities} =
  B.join([
    B.bold("🚀 Deployment Status"),
    deployment_status,
    B.text_link("View logs", "https://example.com/logs?id=123&env=prod"),
    B.date_time("Deployed 5 minutes ago", 1647531900, "r") 
  ], "\n\n")

IO.puts("Length: #{B.utf16_length(text)}")
# Lenght: 115

ExGram.send_message(chat_id, text, entities: entities)
```

**Text size: 115 characters**, that's **95 characters saved**, more room for actual content.

Also, no escaping needed! 

The `{text, entities}` result:

```elixir
{"🚀 Deployment Status\n\nEnvironment: production\nVersion: v2.1.3\nStatus: ✅  Success\n\nView logs\n\nDeployed 5 minutes ago",
 [
   %ExGram.Model.MessageEntity{type: "bold", offset: 0, length: 20,}, 
   %ExGram.Model.MessageEntity{type: "code", offset: 35, length: 10,}, 
   %ExGram.Model.MessageEntity{type: "code", offset: 55, length: 6,}, 
   %ExGram.Model.MessageEntity{type: "bold", offset: 73, length: 7,}, 
   %ExGram.Model.MessageEntity{type: "text_link", offset: 82, length: 9,}, 
   %ExGram.Model.MessageEntity{type: "date_time", offset: 93, length: 22, unix_time: 1647531900, date_time_format: "r"}
 ]}
```

## The MessageEntityBuilder DSL

Every builder function returns a `{text, entities}` tuple. Alias the module for convenience:

```elixir
alias ExGram.Dsl.MessageEntityBuilder, as: B
```

### Inline formatting

```elixir
B.bold("important")
# => {"important", [%MessageEntity{type: "bold", offset: 0, length: 9}]}

B.italic("emphasis")
B.underline("underlined")
B.strikethrough("removed")
B.spoiler("hidden")
B.code("inline_code")
```

### Code blocks

```elixir
B.pre("def hello, do: :world", "elixir")
# => {"def hello, do: :world", [%MessageEntity{type: "pre", offset: 0, length: 21, language: "elixir"}]}
```

### Links, mentions, and special entities

```elixir
B.text_link("ExGram docs", "https://hexdocs.pm/ex_gram")
B.text_mention("Alice", %ExGram.Model.User{id: 123456})
B.custom_emoji("🎉", "5368324170671202286")
B.date_time("noon", DateTime.to_unix(DateTime.utc_now()))
B.date_time("noon", DateTime.to_unix(DateTime.utc_now()), "r") # Date Time formatting, see: https://core.telegram.org/bots/api#date-time-entity-formatting
```

### Working with Emojis

Telegram's entity offsets use **UTF-16 code units**, not grapheme clusters.
Most emojis occupy **2 UTF-16 units** (a surrogate pair):

```elixir
# Simple emoji: 2 UTF-16 units
B.utf16_length("🚀")
# => 2

# Emoji with skin tone modifier: 4 UTF-16 units
B.utf16_length("👍🏽")
# => 4

# Flag emoji (regional indicators): 4 UTF-16 units
B.utf16_length("🇧🇷")
# => 4
```

The builder handles this automatically:

```elixir
B.concat(["Status: ", B.bold("✅ Online")])
# => {"Status: ✅ Online", [%MessageEntity{type: "bold", offset: 10, length: 8}]}
#                                                     ^
#                           Offset accounts for "Status: " (8 chars) + "✅ " (2 UTF-16 units for emoji + 1 space)
```

When building messages with emojis, use the builder functions - they calculate
offsets correctly so you don't have to think about UTF-16 encoding.

### Block-level formatting

```elixir
B.blockquote("Quoted text")
B.expandable_blockquote("Long quoted text that collapses")
```

### Auto-detected entities

These match Telegram's auto-detected entity types, you don't really need them, but you can make them explicit:

```elixir
B.mention("@my_bot")
B.hashtag("#elixir")
B.cashtag("$USD")
B.bot_command("/start@my_bot")
B.url("https://example.com")
B.email("user@example.com")
B.phone_number("+1234567890")
```

## Composing Messages

### Concatenation

`concat/1` joins a list of tuples into one, automatically adjusting entity
offsets:

```elixir
B.concat([B.bold("Hello"), B.text(", "), B.italic("world")])
# => {"Hello, world", [
#   %MessageEntity{type: "bold", offset: 0, length: 5},
#   %MessageEntity{type: "italic", offset: 7, length: 5}
# ]}
```

You can also pass plain strings directly inside `concat/1` - they are
treated as `B.text/1`:

```elixir
B.concat([B.bold("Status:"), " All systems ", B.code("operational")])
```

### Joining with separators

`join/2` inserts a separator (default: `" "`) between non-empty tuples:

```elixir
B.join([B.bold("Status:"), "All systems operational"])
# => {"Status: All systems operational", [%MessageEntity{type: "bold", offset: 0, length: 7}]}
```

Just like `concat/1` plain nodes are transformed with `B.text/1`

## Manipulating Messages

### Trimming

All trim functions adjust entity offsets and lengths accordingly:

```elixir
B.trim(B.concat([B.text("  "), B.bold("hello"), B.text("  ")]))
# => {"hello", [%MessageEntity{type: "bold", offset: 0, length: 5}]}
```

Variants: `trim_leading/1`, `trim_trailing/1`, plus `/2` versions that accept
a custom character set, just like `String.trim` methods.

### Truncating

`truncate/3` cuts a message to a maximum UTF-16 length, appending a suffix
(default `"..."`). Entities that extend past the cut point are trimmed or
dropped:

```elixir
long_msg = B.bold(String.duplicate("a", 100))
B.truncate(long_msg, 20)
# => {"aaaaaaaaaaaaaaaaa...", [%MessageEntity{type: "bold", offset: 0, length: 17}]}
```

The `max_size` parameter is **inclusive** of the truncate text. You can
provide a custom suffix:

```elixir
# Build a notification message
message =
  B.join([
    B.bold("System Alert"),
    B.italic("The database backup process has completed successfully. All data has been verified and stored in the remote location.")
  ], "\n\n")

# Truncate to 50 characters with a custom suffix
{text, entities} = B.truncate(message, 50, " [read more]")
# => {"System Alert\n\nThe database backup proc [read more]",
#     [%MessageEntity{type: "bold", offset: 0, length: 12},  %ExGram.Model.MessageEntity{type: "italic", offset: 14, length: 24}]}
```

Notice:
- The bold entity for "System Alert" is preserved (length: 12)
- The plain italic entity after it was properly reduced at position 38
- The custom suffix " [read more]" (12 chars) was appended
- Total: 38 + 12 = 50 UTF-16 units (exactly `max_size`)

**Important:** The truncate suffix is always plain text (no entities). If you
need formatted truncate text, compose it manually with `concat/1`.

### Splitting

`split/2` breaks a message into parts of at most `max_length` UTF-16 code
units, respecting entity boundaries:

```elixir
parts = B.split(long_message, 4096)
# Each part is a valid {text, entities} tuple
```

Here's a real example showing how `split/2` handles entities:

```elixir
# Build a message with multiple formatted sections
message =
  B.join([
    B.bold("Section 1: "),
    B.text("This is some content in the first section."),
    B.bold("Section 2: "),
    B.italic("More content here in the second section."),
    B.code("some_code_block_that_is_pretty_long_and_detailed")
  ], " ")

# Split with a small max_length to demonstrate behavior
parts = B.split(message, 100)

# Result: 2 parts
# Part 1:
{"Section 1:  This is some content in the first section. Section 2: ",
 [
   %MessageEntity{type: "bold", offset: 0, length: 10},
   %MessageEntity{type: "bold", offset: 57, length: 10}
 ]}

# Part 2:
{"More content here in the second section. some_code_block_that_is_pretty_long_and_detailed",
[
  %ExGram.Model.MessageEntity{type: "italic", offset: 0, length: 40},
  %ExGram.Model.MessageEntity{type: "code", offset: 41, length: 48}
]}
```

Notice:
- The split decided to not split the italic content and moved it to the next section. If there's no space (length of the node is bigger than split length, it will break it)
- Entity offsets in Part 2 are rebased to start from 0 relative to that part's text

This is particularly useful for sending long messages that exceed Telegram's
4096 character limit:

```elixir
{text, entities} = build_long_report()

B.split({text, entities}, 4096)
|> Enum.each(fn {part_text, part_entities} ->
  ExGram.send_message(chat_id, part_text, entities: part_entities)
end)
```

## Sending Entity-Formatted Messages

Inside a bot module that uses `ExGram.Bot`, destructure the tuple and pass
`entities:` in the options:

### Using `answer/3` (DSL helper)

```elixir
def handle({:command, "status", _msg}, context) do
  {text, entities} =
    B.join([
      B.bold("System Status"),
      "All services running.",
    ], "\n\n")

  answer(context, text, entities: entities)
end
```

### Using `ExGram.send_message/3` directly

You can also use the lower-level `ExGram.send_message/3` or any other method that accepts `entities` function directly,
which is useful outside of a bot context or when you need more control:

```elixir
# In any module
def send_notification(chat_id) do
  {text, entities} =
    B.join([
      B.bold("🔔 Notification"),
      B.text("Your order has been shipped!"),
      B.text_link("Track package", "https://tracking.example.com/ABC123")
    ], "\n\n")

  ExGram.send_message(chat_id, text, entities: entities)
end
```

Both approaches accept the same options. The `answer/3` helper is just a
convenience that extracts the chat ID from the context.

## Converting Markdown with `ExGram.Markdown`

If you already have Markdown content - from an API response, user input, or
a template - `ExGram.Markdown` converts it directly into the same
`{text, entities}` tuple format.

### Setup

[MDEx](https://hexdocs.pm/mdex) is an optional dependency of ExGram. Add it to your `mix.exs`:

```elixir
defp deps do
  [
    {:ex_gram, ...},
    {:mdex, "~> 0.11"}
  ]
end
```

### Usage

```elixir
ExGram.Markdown.to_entities("**bold** and *italic*")
# => {"bold and italic", [
#   %MessageEntity{type: "bold", offset: 0, length: 4},
#   %MessageEntity{type: "italic", offset: 9, length: 6}
# ]}
```

It supports the full CommonMark/GFM feature set: bold, italic, strikethrough,
underline, spoiler, inline code, fenced code blocks (with language), links,
images (alt text only), headings (rendered as bold), blockquotes, ordered and
unordered lists, task lists, tables (rendered as `pre`), and thematic breaks.

### The `:skip_blockquotes` option

Telegram does not allow nested blockquotes. If you plan to wrap the entire
output in an expandable blockquote, pass `skip_blockquotes: true` to render
blockquote nodes as indented plain text instead:

```elixir
md = "> Some quoted text\n\nMore content"

inner = ExGram.Markdown.to_entities(md, skip_blockquotes: true)
{text, entities} = B.expandable_blockquote(B.trim(inner))

answer(context, text, entities: entities)
```

## Combining Both Approaches

Since `ExGram.Markdown.to_entities/1` returns the same `{text, entities}`
tuple type as the builder, you can freely compose them:

```elixir
alias ExGram.Dsl.MessageEntityBuilder, as: B

header = B.bold("📋 Report")

body = ExGram.Markdown.to_entities("""
Here are the results:

- **Tests passed:** 42
- **Tests failed:** 0
- *Coverage:* `98.5%`
""")

{text, entities} = B.join([header, B.trim(body)], "\n\n")
answer(context, text, entities: entities)
```

This lets you mix programmatically built sections with Markdown-sourced
content in a single message.

## Next Steps

- [Sending Messages](sending-messages.md) - DSL for simpler bots
- [Middlewares](middlewares.md) - Add preprocessing logic
- [Low-Level API](low-level-api.md) - Direct API calls for complex scenarios
- [Cheatsheet](cheatsheet.md) - Quick reference for all DSL functions
