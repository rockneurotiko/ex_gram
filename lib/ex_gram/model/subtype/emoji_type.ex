defimpl ExGram.Model.Subtype, for: ExGram.Model.EmojiType do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "emoji"), do: ExGram.Model.EmojiTypeEmoji
  def subtype(_, "custom_emoji"), do: ExGram.Model.EmojiTypeCustomEmoji
end
