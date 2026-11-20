defimpl ExGram.Model.Subtype, for: ExGram.Model.ChatShareTheme do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "emoji"), do: ExGram.Model.ChatShareThemeEmoji
  def subtype(_, "unique_gift"), do: ExGram.Model.ChatShareThemeUniqueGift
end
