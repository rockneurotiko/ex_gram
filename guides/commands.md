# Commands

`ExGram` provides a `command` macro to declare bot commands with descriptions, visibility scopes, and language translations. When `setup_commands: true` is set on the bot, these declarations are automatically registered with the Telegram API on startup, making your commands appear in the autocomplete menu for users.

## Basic usage

The simplest way to declare a command is with just a name and a description:

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true

  command(:start, description: "Start the bot")

  def handle({:command, :start, _msg}, context) do
    answer(context, "Welcome!")
  end
end
```

Commands without a `description` are still valid - they will be handled by your bot but won't be registered in the Telegram command menu. This is useful for "hidden" commands or not useful commands in day-to-day:

```elixir
command(:start)  # no description - works but won't show in menu
command(:debug)  # no description - works but won't show in menu

def handle({:command, :start, _msg}, context) do
  answer(context, "Hey!")
end

def handle({:command, :debug, _msg}, context) do
  answer(context, "Debug mode")
end
```

## Options reference

- `:description` (string) - text shown in Telegram's command menu. Required if any other of this options are set.
- `:scopes` (list) - scopes where the command is visible. See [Scopes](#scopes).
- `:lang` (keyword list) - language-specific overrides, IETF language code atom. See [Language translations](#language-translations).
- `:name` (atom) - atom used for dispatch pattern matching. Defaults to the command name as an atom. Useful when you want a different name in the handler.

```elixir
# Override the handler atom - dispatches as {:command, :begin, msg}
command(:start, name: :begin, description: "Start the bot")

def handle({:command, :begin, _msg}, context) do
  answer(context, "Welcome!")
end
```

## Scopes

Telegram's [BotCommandScope](https://core.telegram.org/bots/api#botcommandscope) controls where commands appear in the autocomplete menu. By declaring scopes you can show different command sets to different audiences - for example, showing admin commands only to group administrators.

### Simple scopes

These are plain atoms:

| Scope                      | Who sees it                                   |
|----------------------------|-----------------------------------------------|
| `:default`                 | All users when no more specific scope applies |
| `:all_private_chats`       | Users in any private (1-on-1) chat            |
| `:all_group_chats`         | Users in any group or supergroup chat         |
| `:all_chat_administrators` | Administrators in any group chat              |

```elixir
command(:help,
  description: "Get help",
  scopes: [:all_private_chats, :all_group_chats]
)

command(:ban,
  description: "Ban a user",
  scopes: [:all_chat_administrators]
)
```

### Parametric scopes

These are tuples that target specific chats or users:

- `{:chat, chat_ids: [100, 200]}` - visible in the listed chats. Expands to one API registration per chat.
- `{:chat_administrators, chat_ids: [100]}` - visible to administrators of the listed chats.
- `{:chat_member, chat_id: 1, user_ids: [10, 20]}` - visible to specific users in a specific chat.

```elixir
command(:notify,
  description: "Send a notification",
  scopes: [{:chat, chat_ids: [123_456, 789_012]}]
)

command(:secret,
  description: "Secret command",
  scopes: [{:chat_member, chat_id: 123_456, user_ids: [111, 222]}]
)
```

### Scope inheritance

The `scopes` option controls not just where a command appears, but how it interacts with the rest of your command list.

**Commands without `scopes`** (or with `scopes: nil`). All the other scopes will inherit this command, meaning they will appear everywhere other commands appear.

**Commands with `scopes: []`** (empty list) fall back to `:default`. It will only appear to users with the default scope.

**If no command defines any scope**, everything falls back to `:default`.

**Commands with explicit scopes** appear **only** in those scopes.

```elixir
# "help" has no scopes
command(:help, description: "Get help")

# "stats" is only in :all_private_chats
command(:stats,
  description: "Your stats",
  scopes: [:all_private_chats]
)
```

In this example, both `:stats` and `:help` appear in `:all_private_chats`. And on the `:default` scope (group chats for example) only the `:help` command would appear.

## Language translations

The `:lang` option lets you provide per-language overrides for the command name and description. Each key is an IETF language code atom (`:es`, `:pt`, `:it`, etc.) and the value is a keyword list with `:command` and/or `:description`.

### Translating descriptions

```elixir
command(:start,
  description: "Start the bot",
  scopes: [:default],
  lang: [
    es: [description: "Iniciar el bot"],
    pt: [description: "Iniciar o bot"]
  ]
)
```

Spanish users see "Iniciar el bot", Portuguese users see "Iniciar o bot", everyone else sees "Start the bot".

### Translating command names

You can also change the command name itself for a language:

```elixir
command(:help,
  description: "Get help",
  scopes: [:default],
  lang: [es: [command: "ayuda", description: "Obtener ayuda"]]
)
```

Spanish users see `/ayuda` in their menu. ExGram automatically registers `/ayuda` as a dispatch alias, so it routes to the same `:help` handler - no extra `handle` clause needed:

```elixir
def handle({:command, :help, _msg}, context) do
  # Here the user will have `language_code` if you want to send translated messages
  answer(context, "Here is some help!")
end
```

### Inheriting values

A lang entry does not need to override both fields:

- Omitting `:description` inherits the base description.
- Omitting `:command` keeps the base command name.

```elixir
command(:help,
  description: "Get help",
  lang: [es: [command: "ayuda"]]  # description inherited from base
)
```

### Merge behavior

Untranslated commands are automatically merged into every language group. This ensures users of any language always see the full command list - translated commands appear in their translated form, untranslated commands fall back to their base form.

```elixir
command(:start,
  description: "Start the bot",
  lang: [es: [description: "Iniciar el bot"]]
)
command(:help, description: "Get help")
```

Spanish users see both `start` ("Iniciar el bot") and `help` ("Get help"). The untranslated `:help` is merged in automatically.

If a command renames itself in a translation (e.g. `help` -> `ayuda`), the original name (`help`) is excluded from that language group to avoid showing duplicate entries.

## Scopes and languages combined

Translations apply independently to each scope. If a command appears in multiple scopes, each (scope + language) combination gets its own Telegram API registration.

```elixir
command(:greet,
  description: "Greet users",
  scopes: [:all_private_chats, :all_group_chats],
  lang: [es: [description: "Saludar usuarios"]]
)
```

This produces four registrations:

- `:all_private_chats` (no lang) - "Greet users"
- `:all_group_chats` (no lang) - "Greet users"
- `:all_private_chats` + `"es"` - "Saludar usuarios"
- `:all_group_chats` + `"es"` - "Saludar usuarios"

## Full example

```elixir
defmodule MyBot do
  use ExGram.Bot, name: :my_bot, setup_commands: true

  middleware(ExGram.Middleware.IgnoreUsername)

  # Visible to all users in all contexts
  command(:start,
    description: "Start the bot",
    lang: [
      es: [description: "Iniciar el bot"],
      pt: [description: "Iniciar o bot"]
    ]
  )

  # Only visible in private chats, with a translated name for Spanish
  command(:help,
    description: "Get help",
    scopes: [:all_private_chats],
    lang: [es: [command: "ayuda", description: "Obtener ayuda"]]
  )

  # Only visible to group administrators
  command(:ban,
    description: "Ban a user",
    scopes: [:all_chat_administrators],
    lang: [es: [description: "Prohibir usuario"]]
  )

  # Hidden command - no description, won't appear in the menu
  command(:debug)

  def handle({:command, :start, _msg}, context) do
    answer(context, "Welcome! Use /help for a list of commands.")
  end

  # Handles both /help and /ayuda (Spanish alias)
  def handle({:command, :help, _msg}, context) do
    answer(context, "Here is some help!")
  end

  def handle({:command, :ban, %{text: target}}, context) do
    answer(context, "Banned #{target}")
  end

  def handle({:command, :debug, _msg}, context) do
    answer(context, "Debug info: ...")
  end

  def handle(_, _context), do: :ok
end
```
