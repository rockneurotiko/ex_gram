defimpl ExGram.Model.Subtype, for: ExGram.Model.ChatMember do
  def selector_value(_, params) do
    params.status
  end

  def subtype(_, "creator"), do: ExGram.Model.ChatMemberOwner
  def subtype(_, "administrator"), do: ExGram.Model.ChatMemberAdministrator
  def subtype(_, "member"), do: ExGram.Model.ChatMemberMember
  def subtype(_, "restricted"), do: ExGram.Model.ChatMemberRestricted
  def subtype(_, "left"), do: ExGram.Model.ChatMemberLeft
  def subtype(_, "kicked"), do: ExGram.Model.ChatMemberBanned
end
