defimpl ExGram.Model.Subtype, for: ExGram.Model.ChatBoostSource do
  def selector_value(_, params) do
    params.source
  end

  def subtype(_, "premium"), do: ExGram.Model.ChatBoostSourcePremium
  def subtype(_, "gift_code"), do: ExGram.Model.ChatBoostSourceGiftCode
  def subtype(_, "giveaway"), do: ExGram.Model.ChatBoostSourceGiveaway
end
