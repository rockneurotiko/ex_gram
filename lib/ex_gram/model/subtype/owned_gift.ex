defimpl ExGram.Model.Subtype, for: ExGram.Model.OwnedGift do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "regular"), do: ExGram.Model.OwnedGiftRegular
  def subtype(_, "unique"), do: ExGram.Model.OwnedGiftUnique
end
