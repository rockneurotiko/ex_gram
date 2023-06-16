defimpl ExGram.Model.Subtype, for: ExGram.Model.BotCommandScope do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "default"), do: ExGram.Model.BotCommandScopeDefault
  def subtype(_, "all_private_chats"), do: ExGram.Model.BotCommandScopeAllPrivateChats
  def subtype(_, "all_group_chats"), do: ExGram.Model.BotCommandScopeAllGroupChats
  def subtype(_, "chat"), do: ExGram.Model.BotCommandScopeChat
  def subtype(_, "chat_administrators"), do: ExGram.Model.BotCommandScopeChatAdministrators
  def subtype(_, "chat_member"), do: ExGram.Model.BotCommandScopeChatMember

  def subtype(_, "all_chat_administrators"),
    do: ExGram.Model.BotCommandScopeAllChatAdministrators
end
