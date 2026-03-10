defmodule ExGram.Bot.SetupCommands do
  @moduledoc """
  Handles registering bot commands with the Telegram API,
  expanding scopes and language variations.

  Command definitions are validated at compile time by
  `ExGram.Bot.ValidateCommands`.
  """

  alias ExGram.Model.BotCommandScopeAllChatAdministrators
  alias ExGram.Model.BotCommandScopeAllGroupChats
  alias ExGram.Model.BotCommandScopeAllPrivateChats
  alias ExGram.Model.BotCommandScopeChat
  alias ExGram.Model.BotCommandScopeChatAdministrators
  alias ExGram.Model.BotCommandScopeChatMember
  alias ExGram.Model.BotCommandScopeDefault

  def setup(commands, token) do
    commands
    |> build()
    |> Enum.each(fn {cmds, opts} ->
      ExGram.set_my_commands(cmds, [{:token, token} | opts])
    end)
  end

  def build(commands) do
    commands_with_description = Enum.filter(commands, & &1[:opts][:description])
    used_scopes = collect_used_scopes(commands_with_description)

    grouped =
      commands_with_description
      |> Enum.flat_map(&expand_command(&1, used_scopes))
      |> Enum.group_by(fn {scope, lang, _cmd, _base} -> {scope, lang} end, fn {_scope, _lang, cmd, base} ->
        {cmd, base}
      end)

    Enum.map(grouped, fn {{scope, lang}, cmd_pairs} ->
      cmd_pairs = if lang, do: merge_with_base(grouped, scope, cmd_pairs), else: cmd_pairs
      cmds = Enum.map(cmd_pairs, fn {cmd, _base} -> cmd end)
      api_opts = [scope: scope]
      api_opts = if lang, do: Keyword.put(api_opts, :language_code, lang), else: api_opts
      {cmds, api_opts}
    end)
  end

  defp collect_used_scopes(commands_with_description) do
    commands_with_description
    |> Enum.flat_map(fn cmd ->
      case cmd[:opts][:scopes] do
        nil -> []
        scopes -> scopes
      end
    end)
    |> Enum.uniq()
  end

  defp expand_command(command, used_scopes) do
    opts = command[:opts]

    for scope_struct <- expand_scopes(opts[:scopes], used_scopes),
        {lang_code, cmd_text, cmd_desc, base_cmd} <- expand_langs(command[:command], opts) do
      bot_cmd = %ExGram.Model.BotCommand{command: cmd_text, description: cmd_desc}
      {scope_struct, lang_code, bot_cmd, base_cmd}
    end
  end

  defp expand_langs(base_cmd, opts) do
    base_desc = opts[:description]
    lang_overrides = opts[:lang] || []

    default = [{nil, base_cmd, base_desc, base_cmd}]

    translations =
      for {lang_code, overrides} <- lang_overrides do
        lang_str = Atom.to_string(lang_code)
        cmd_text = overrides[:command] || base_cmd
        cmd_desc = overrides[:description] || base_desc
        {lang_str, cmd_text, cmd_desc, base_cmd}
      end

    default ++ translations
  end

  defp merge_with_base(grouped, scope, lang_cmd_pairs) do
    base_cmd_pairs = Map.get(grouped, {scope, nil}, [])
    translated_base_names = MapSet.new(lang_cmd_pairs, fn {_cmd, base} -> base end)
    untranslated = Enum.reject(base_cmd_pairs, fn {_cmd, base} -> base in translated_base_names end)
    lang_cmd_pairs ++ untranslated
  end

  def expand_scopes(nil, used_scopes), do: expand_scopes(used_scopes, used_scopes)
  def expand_scopes([], used_scopes), do: expand_scopes([:default], used_scopes)

  def expand_scopes(scopes, _used_scopes) when is_list(scopes) do
    Enum.flat_map(scopes, &List.wrap(expand_scope(&1)))
  end

  defp expand_scope(:default), do: %BotCommandScopeDefault{type: "default"}
  defp expand_scope(:all_private_chats), do: %BotCommandScopeAllPrivateChats{type: "all_private_chats"}
  defp expand_scope(:all_group_chats), do: %BotCommandScopeAllGroupChats{type: "all_group_chats"}

  defp expand_scope(:all_chat_administrators) do
    %BotCommandScopeAllChatAdministrators{type: "all_chat_administrators"}
  end

  defp expand_scope({:chat, opts}) do
    Enum.map(opts[:chat_ids], &%BotCommandScopeChat{type: "chat", chat_id: &1})
  end

  defp expand_scope({:chat_administrators, opts}) do
    Enum.map(opts[:chat_ids], &%BotCommandScopeChatAdministrators{type: "chat_administrators", chat_id: &1})
  end

  defp expand_scope({:chat_member, opts}) do
    Enum.map(opts[:user_ids], &%BotCommandScopeChatMember{type: "chat_member", chat_id: opts[:chat_id], user_id: &1})
  end
end
