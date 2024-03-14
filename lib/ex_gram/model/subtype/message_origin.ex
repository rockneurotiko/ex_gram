defimpl ExGram.Model.Subtype, for: ExGram.Model.MessageOrigin do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "user"), do: ExGram.Model.MessageOriginUser
  def subtype(_, "hidden_user"), do: ExGram.Model.MessageOriginHiddenUser
  def subtype(_, "chat"), do: ExGram.Model.MessageOriginChat
  def subtype(_, "channel"), do: ExGram.Model.MessageOriginChannel
end
