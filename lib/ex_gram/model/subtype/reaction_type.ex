defimpl ExGram.Model.Subtype, for: ExGram.Model.ReactionType do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "emoji"), do: ExGram.Model.ReactionTypeEmoji
  def subtype(_, "custom_emoji"), do: ExGram.Model.ReactionTypeCustomEmoji
end
