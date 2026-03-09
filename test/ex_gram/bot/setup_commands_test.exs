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
    assert pairs(commands_for(result, %BotCommandScopeDefault{type: "default"})) == [{"start", "Begin"}]
  end

  test "commands without description are excluded" do
    result = SetupCommands.build([cmd("hidden", []), cmd("visible", description: "Yes")])
    assert names(commands_for(result, %BotCommandScopeDefault{type: "default"})) == ["visible"]
  end

  test "empty commands list" do
    assert SetupCommands.build([]) == []
  end

  # --- Tests: scopes ---

  test "explicit scope" do
    result = SetupCommands.build([cmd("admin", description: "Admin cmd", scopes: [:all_chat_administrators])])

    assert pairs(commands_for(result, %BotCommandScopeAllChatAdministrators{type: "all_chat_administrators"})) ==
             [{"admin", "Admin cmd"}]

    assert commands_for(result, %BotCommandScopeDefault{type: "default"}) == []
  end

  test "multiple scopes on one command" do
    result =
      SetupCommands.build([cmd("help", description: "Help", scopes: [:all_private_chats, :all_group_chats])])

    assert names(commands_for(result, %BotCommandScopeAllPrivateChats{type: "all_private_chats"})) == ["help"]
    assert names(commands_for(result, %BotCommandScopeAllGroupChats{type: "all_group_chats"})) == ["help"]
  end

  test "nil scopes inherits all used scopes" do
    result =
      SetupCommands.build([
        cmd("specific", description: "Specific", scopes: [:all_private_chats]),
        cmd("everywhere", description: "Everywhere")
      ])

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
    assert names(commands_for(result, %BotCommandScopeDefault{type: "default"})) == ["fallback"]
  end

  test "chat scope expands per chat_id" do
    result =
      SetupCommands.build([
        cmd("notify", description: "Notify", scopes: [{:chat, chat_ids: [100, 200]}])
      ])

    assert names(commands_for(result, %BotCommandScopeChat{type: "chat", chat_id: 100})) == ["notify"]
    assert names(commands_for(result, %BotCommandScopeChat{type: "chat", chat_id: 200})) == ["notify"]
  end

  test "chat_administrators scope expands per chat_id" do
    result =
      SetupCommands.build([
        cmd("ban", description: "Ban", scopes: [{:chat_administrators, chat_ids: [42, 99]}])
      ])

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

    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"ayuda", "Ayuda"}, {"help", "Help"}]
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

    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"ayuda", "Help"}, {"help", "Help"}]
  end

  # --- Tests: merge_with_base ---

  test "untranslated commands are merged into lang entries" do
    result =
      SetupCommands.build([
        cmd("start", description: "Start", scopes: [:default], lang: [es: [description: "Iniciar"]]),
        cmd("help", description: "Help", scopes: [:default])
      ])

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

    default = %BotCommandScopeDefault{type: "default"}
    assert pairs(commands_for(result, default, "es")) == [{"start", "Iniciar"}, {"stop", "Parar"}]
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

    private = %BotCommandScopeAllPrivateChats{type: "all_private_chats"}
    assert names(commands_for(result, private)) == ["specific", "global"]

    # "global" translated => base "global" not duplicated; "specific" merged from base
    assert pairs(commands_for(result, private, "es")) == [
             {"global", "Global es"},
             {"specific", "Specific"}
           ]
  end
end
