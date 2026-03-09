defmodule ExGram.Bot.SetupCommandsTest do
  use ExUnit.Case, async: true

  alias ExGram.Bot.SetupCommands
  alias ExGram.Model.BotCommandScopeAllChatAdministrators
  alias ExGram.Model.BotCommandScopeAllGroupChats
  alias ExGram.Model.BotCommandScopeAllPrivateChats
  alias ExGram.Model.BotCommandScopeChat
  alias ExGram.Model.BotCommandScopeChatAdministrators
  alias ExGram.Model.BotCommandScopeChatMember
  alias ExGram.Model.BotCommandScopeDefault

  defp cmd(name, opts), do: [command: name, opts: opts]

  # Find commands matching a scope struct and optional lang in build/1 output
  defp commands_for(build_result, scope, lang \\ nil) do
    Enum.find_value(build_result, [], fn {cmds, opts} ->
      opts[:scope] == scope && opts[:language_code] == lang && cmds
    end)
  end

  defp names(cmds), do: Enum.map(cmds, & &1.command)
  defp pairs(cmds), do: Enum.map(cmds, &{&1.command, &1.description})

  # --- Tests: basic ---

  test "single command with default scope" do
    result = SetupCommands.build([cmd("start", description: "Begin")])
    assert length(result) == 1
    assert pairs(commands_for(result, %BotCommandScopeDefault{type: "default"})) == [{"start", "Begin"}]
  end

  test "commands without description are excluded" do
    result = SetupCommands.build([cmd("hidden", []), cmd("visible", description: "Yes")])
    assert length(result) == 1
    assert names(commands_for(result, %BotCommandScopeDefault{type: "default"})) == ["visible"]
  end

  test "empty commands list" do
    assert SetupCommands.build([]) == []
  end

  # --- Tests: scopes ---

  test "explicit scope" do
    result = SetupCommands.build([cmd("admin", description: "Admin cmd", scopes: [:all_chat_administrators])])

    assert length(result) == 1

    assert pairs(commands_for(result, %BotCommandScopeAllChatAdministrators{type: "all_chat_administrators"})) ==
             [{"admin", "Admin cmd"}]

    assert commands_for(result, %BotCommandScopeDefault{type: "default"}) == []
  end

  test "multiple scopes on one command" do
    result =
      SetupCommands.build([cmd("help", description: "Help", scopes: [:all_private_chats, :all_group_chats])])

    assert length(result) == 2
    assert names(commands_for(result, %BotCommandScopeAllPrivateChats{type: "all_private_chats"})) == ["help"]
    assert names(commands_for(result, %BotCommandScopeAllGroupChats{type: "all_group_chats"})) == ["help"]
  end

  test "nil scopes inherits all used scopes" do
    result =
      SetupCommands.build([
        cmd("specific", description: "Specific", scopes: [:all_private_chats]),
        cmd("everywhere", description: "Everywhere")
      ])

    assert length(result) == 1

    assert names(commands_for(result, %BotCommandScopeAllPrivateChats{type: "all_private_chats"})) ==
             ["specific", "everywhere"]

    assert commands_for(result, %BotCommandScopeDefault{type: "default"}) == []
  end

  test "all commands without scopes fall back to :default" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start"),
        cmd("help", description: "Help")
      ])

    assert names(commands_for(result, %BotCommandScopeDefault{type: "default"})) == ["start", "help"]
    assert length(result) == 1
  end

  test "empty scopes list falls back to :default" do
    result = SetupCommands.build([cmd("fallback", description: "FB", scopes: [])])
    assert length(result) == 1
    assert names(commands_for(result, %BotCommandScopeDefault{type: "default"})) == ["fallback"]
  end

  test "chat scope expands per chat_id" do
    result =
      SetupCommands.build([
        cmd("notify", description: "Notify", scopes: [{:chat, chat_ids: [100, 200]}])
      ])

    assert length(result) == 2
    assert names(commands_for(result, %BotCommandScopeChat{type: "chat", chat_id: 100})) == ["notify"]
    assert names(commands_for(result, %BotCommandScopeChat{type: "chat", chat_id: 200})) == ["notify"]
  end

  test "chat_administrators scope expands per chat_id" do
    result =
      SetupCommands.build([
        cmd("ban", description: "Ban", scopes: [{:chat_administrators, chat_ids: [42, 99]}])
      ])

    assert length(result) == 2

    assert names(commands_for(result, %BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: 42})) ==
             ["ban"]

    assert names(commands_for(result, %BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: 99})) ==
             ["ban"]
  end

  test "chat_member scope expands per user_id" do
    result =
      SetupCommands.build([
        cmd("secret",
          description: "Secret",
          scopes: [{:chat_member, chat_id: 1, user_ids: [10, 20]}]
        )
      ])

    assert length(result) == 2

    assert names(commands_for(result, %BotCommandScopeChatMember{type: "chat_member", chat_id: 1, user_id: 10})) ==
             ["secret"]

    assert names(commands_for(result, %BotCommandScopeChatMember{type: "chat_member", chat_id: 1, user_id: 20})) ==
             ["secret"]
  end

  test "nil scopes inherits parametric (chat) used scopes" do
    result =
      SetupCommands.build([
        cmd("notify", description: "Notify", scopes: [{:chat, chat_ids: [100]}]),
        cmd("everywhere", description: "Everywhere")
      ])

    assert length(result) == 1

    assert names(commands_for(result, %BotCommandScopeChat{type: "chat", chat_id: 100})) ==
             ["notify", "everywhere"]

    assert commands_for(result, %BotCommandScopeDefault{type: "default"}) == []
  end

  # --- Tests: langs ---

  test "language translation creates separate entry" do
    result =
      SetupCommands.build([
        cmd("start", description: "Begin", scopes: [:default], lang: [es: [description: "Iniciar"]])
      ])

    assert length(result) == 2
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default)) == [{"start", "Begin"}]
    # same command name => base "start" is not duplicated in merge
    assert pairs(commands_for(result, default, "es")) == [{"start", "Iniciar"}]
  end

  test "language override can change command text" do
    result =
      SetupCommands.build([
        cmd("help",
          description: "Help",
          scopes: [:default],
          lang: [es: [command: "ayuda", description: "Ayuda"]]
        )
      ])

    assert length(result) == 2
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, nil)) == [{"help", "Help"}]
    assert pairs(commands_for(result, default, "es")) == [{"ayuda", "Ayuda"}]
  end

  test "language override with only description inherits command name" do
    result =
      SetupCommands.build([
        cmd("start",
          description: "Start",
          scopes: [:default],
          lang: [es: [description: "Comenzar"]]
        )
      ])

    assert length(result) == 2
    # translated entry + merged base (same command name => no duplicate)
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"start", "Comenzar"}]
  end

  test "multiple languages" do
    result =
      SetupCommands.build([
        cmd("start",
          description: "Start",
          scopes: [:default],
          lang: [es: [description: "Iniciar"], it: [description: "Avviare"]]
        )
      ])

    assert length(result) == 3
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"start", "Iniciar"}]
    assert pairs(commands_for(result, default, "it")) == [{"start", "Avviare"}]
  end

  test "lang entry with no description inherits base description" do
    result =
      SetupCommands.build([
        cmd("help",
          description: "Help",
          scopes: [:default],
          lang: [es: [command: "ayuda"]]
        )
      ])

    assert length(result) == 2
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, nil)) == [{"help", "Help"}]
    assert pairs(commands_for(result, default, "es")) == [{"ayuda", "Help"}]
  end

  # --- Tests: merge_with_base ---

  test "untranslated commands are merged into lang entries" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start", scopes: [:default], lang: [es: [description: "Iniciar"]]),
        cmd("help", description: "Help", scopes: [:default])
      ])

    assert length(result) == 2
    default = %BotCommandScopeDefault{type: "default"}
    assert names(commands_for(result, default)) == ["start", "help"]
    # "start" translated + "help" merged from base
    assert pairs(commands_for(result, default, "es")) == [{"start", "Iniciar"}, {"help", "Help"}]
  end

  test "translated command is not duplicated in merge" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start", scopes: [:default], lang: [es: [description: "Iniciar"]]),
        cmd("stop", description: "Stop", scopes: [:default], lang: [es: [description: "Parar"]])
      ])

    assert length(result) == 2
    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"start", "Iniciar"}, {"stop", "Parar"}]
  end

  test "translated command with renamed text excludes original from lang group" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start the bot"),
        cmd("help", description: "Get help information", lang: [es: [command: "ayuda"]])
      ])

    default = %BotCommandScopeDefault{type: "default"}
    assert length(result) == 2
    assert names(commands_for(result, default)) == ["start", "help"]
    assert names(commands_for(result, default, "es")) == ["ayuda", "start"]
  end

  # --- Tests: scopes + langs combined ---

  test "lang translations applied per scope" do
    result =
      SetupCommands.build([
        cmd("greet",
          description: "Greet",
          scopes: [:all_private_chats, :all_group_chats],
          lang: [es: [description: "Saludar"]]
        )
      ])

    assert length(result) == 4

    assert pairs(commands_for(result, %BotCommandScopeAllPrivateChats{type: "all_private_chats"}, "es")) ==
             [{"greet", "Saludar"}]

    assert pairs(commands_for(result, %BotCommandScopeAllGroupChats{type: "all_group_chats"}, "es")) ==
             [{"greet", "Saludar"}]
  end

  test "nil scopes with translations inherit used scopes" do
    result =
      SetupCommands.build([
        cmd("specific", description: "Specific", scopes: [:all_private_chats]),
        cmd("global",
          description: "Global",
          lang: [es: [description: "Global es"]]
        )
      ])

    assert length(result) == 2
    private = %BotCommandScopeAllPrivateChats{type: "all_private_chats"}
    assert names(commands_for(result, private)) == ["specific", "global"]

    # "global" translated => base "global" not duplicated; "specific" merged from base
    assert pairs(commands_for(result, private, "es")) == [
             {"global", "Global es"},
             {"specific", "Specific"}
           ]
  end

  test "complex scenario with multiple commands, scopes, languages, and parametric expansion" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start the bot", lang: [es: [description: "Iniciar el bot"]]),
        cmd("help",
          description: "Get help",
          # By specifying :default, it will only be included on the default + all_private_chats, it does not
          # get inherited by other scopes because we were explicit about it.
          scopes: [:default, :all_private_chats],
          lang: [es: [command: "ayuda"], pt: [description: "Ajuda"]]
        ),
        cmd("settings", description: "Settings", scopes: [:default]),
        cmd("stats",
          description: "View stats",
          scopes: [:all_private_chats],
          lang: [es: [command: "estadisticas", description: "Ver estadisticas"]]
        ),
        cmd("admin",
          description: "Admin tools",
          scopes: [{:chat_administrators, chat_ids: [100, 200]}],
          lang: [pt: [description: "Ferramentas admin"]]
        )
      ])

    assert length(result) == 12

    default = %BotCommandScopeDefault{type: "default"}
    private = %BotCommandScopeAllPrivateChats{type: "all_private_chats"}
    chat_admin_100 = %BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: 100}
    chat_admin_200 = %BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: 200}

    # Default scope - nil lang
    assert pairs(commands_for(result, default, nil)) == [
             {"start", "Start the bot"},
             {"help", "Get help"},
             {"settings", "Settings"}
           ]

    # Default scope - es lang: start translated, help renamed to ayuda, settings merged
    assert pairs(commands_for(result, default, "es")) == [
             {"start", "Iniciar el bot"},
             {"ayuda", "Get help"},
             {"settings", "Settings"}
           ]

    # Default scope - pt lang: help translated, start and settings merged
    assert pairs(commands_for(result, default, "pt")) == [
             {"help", "Ajuda"},
             {"start", "Start the bot"},
             {"settings", "Settings"}
           ]

    # All private chats scope - nil lang
    assert pairs(commands_for(result, private, nil)) == [
             {"start", "Start the bot"},
             {"help", "Get help"},
             {"stats", "View stats"}
           ]

    # All private chats scope - es lang: all 3 have es translations
    assert pairs(commands_for(result, private, "es")) == [
             {"start", "Iniciar el bot"},
             {"ayuda", "Get help"},
             {"estadisticas", "Ver estadisticas"}
           ]

    # All private chats scope - pt lang: help translated, start and stats merged
    assert pairs(commands_for(result, private, "pt")) == [
             {"help", "Ajuda"},
             {"start", "Start the bot"},
             {"stats", "View stats"}
           ]

    # Chat administrators (100) - nil lang
    assert pairs(commands_for(result, chat_admin_100, nil)) == [
             {"start", "Start the bot"},
             {"admin", "Admin tools"}
           ]

    # Chat administrators (100) - es lang: start translated, admin merged
    assert pairs(commands_for(result, chat_admin_100, "es")) == [
             {"start", "Iniciar el bot"},
             {"admin", "Admin tools"}
           ]

    # Chat administrators (100) - pt lang: admin translated, start merged
    assert pairs(commands_for(result, chat_admin_100, "pt")) == [
             {"admin", "Ferramentas admin"},
             {"start", "Start the bot"}
           ]

    # Chat administrators (200) - nil lang
    assert pairs(commands_for(result, chat_admin_200, nil)) == [
             {"start", "Start the bot"},
             {"admin", "Admin tools"}
           ]

    # Chat administrators (200) - es lang: start translated, admin merged
    assert pairs(commands_for(result, chat_admin_200, "es")) == [
             {"start", "Iniciar el bot"},
             {"admin", "Admin tools"}
           ]

    # Chat administrators (200) - pt lang: admin translated, start merged
    assert pairs(commands_for(result, chat_admin_200, "pt")) == [
             {"admin", "Ferramentas admin"},
             {"start", "Start the bot"}
           ]
  end
end
