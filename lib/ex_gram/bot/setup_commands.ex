defmodule ExGram.Bot.SetupCommands do
  @moduledoc """
  Handles registering bot commands with the Telegram API,
  expanding scopes and language variations.
  """

  alias ExGram.Model.BotCommandScopeAllGroupChats
  alias ExGram.Model.BotCommandScopeAllPrivateChats
  alias ExGram.Model.BotCommandScopeChat
  alias ExGram.Model.BotCommandScopeChatAdministrators
  alias ExGram.Model.BotCommandScopeAllChatAdministrators
  alias ExGram.Model.BotCommandScopeChatMember
  alias ExGram.Model.BotCommandScopeDefault

  def setup(commands, token) do
    commands
    |> expand_commands_by_scopes_and_langs()
    |> Enum.group_by(fn {scope, lang, _cmd} -> {scope, lang} end, fn {_scope, _lang, cmd} -> cmd end)
    |> Enum.each(fn {{scope, lang}, cmds} ->
      opts = [scope: scope, token: token]
      opts = if lang, do: [{:language_code, lang} | opts], else: opts
      ExGram.set_my_commands(cmds, opts)
    end)
  end

  defp expand_commands_by_scopes_and_langs(commands) do
    for command <- commands,
        command[:description] != nil,
        scope_struct <- expand_scopes(command[:scopes]),
        {lang_code, cmd_text, cmd_desc} <- expand_langs(command) do
      bot_cmd = %ExGram.Model.BotCommand{
        command: cmd_text,
        description: cmd_desc
      }

      {scope_struct, lang_code, bot_cmd}
    end
  end

  defp expand_langs(command) do
    base_cmd = command[:command]
    base_desc = command[:description]
    lang_overrides = command[:lang] || []

    default = [{nil, base_cmd, base_desc}]

    translations =
      for {lang_code, overrides} <- lang_overrides do
        lang_str = Atom.to_string(lang_code)
        cmd_text = overrides[:command] || base_cmd
        cmd_desc = overrides[:description] || base_desc
        {lang_str, cmd_text, cmd_desc}
      end

    default ++ translations
  end

  # nil defaults to [:default], empty list [] means no scopes (command won't be registered)
  defp expand_scopes(nil), do: [%BotCommandScopeDefault{type: "default"}]
  defp expand_scopes([]), do: []
  defp expand_scopes(scopes) when is_list(scopes), do: Enum.flat_map(scopes, &expand_scope/1)

  defp expand_scope(:default), do: [%BotCommandScopeDefault{type: "default"}]
  defp expand_scope(:all_private_chats), do: [%BotCommandScopeAllPrivateChats{type: "all_private_chats"}]
  defp expand_scope(:all_group_chats), do: [%BotCommandScopeAllGroupChats{type: "all_group_chats"}]

  defp expand_scope(:all_chat_administrators),
    do: [%BotCommandScopeAllChatAdministrators{type: "all_chat_administrators"}]

  defp expand_scope({:chat, opts}) do
    for chat_id <- Keyword.get(opts, :chat_ids, []) do
      %BotCommandScopeChat{type: "chat", chat_id: chat_id}
    end
  end

  defp expand_scope({:chat_administrators, opts}) do
    for chat_id <- Keyword.get(opts, :chat_ids, []) do
      %BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: chat_id}
    end
  end

  defp expand_scope({:chat_member, opts}) do
    chat_id = Keyword.get(opts, :chat_id)

    for user_id <- Keyword.get(opts, :user_ids, []) do
      %BotCommandScopeChatMember{type: "chat_member", chat_id: chat_id, user_id: user_id}
    end
  end

  defp expand_scope(scope_type) do
    raise ArgumentError,
          "Unknown scope: #{inspect(scope_type)}. " <>
            "Atom scopes: :default, :all_private_chats, :all_group_chats, :all_chat_administrators. " <>
            "Tuple scopes: {:chat, opts}, {:chat_administrators, opts}, {:chat_member, opts}"
  end
end
