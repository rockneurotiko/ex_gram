defimpl ExGram.Model.Subtype, for: ExGram.Model.TransactionPartner do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "user"), do: ExGram.Model.TransactionPartnerUser
  def subtype(_, "chat"), do: ExGram.Model.TransactionPartnerChat
  def subtype(_, "affiliate_program"), do: ExGram.Model.TransactionPartnerAffiliateProgram
  def subtype(_, "fragment"), do: ExGram.Model.TransactionPartnerFragment
  def subtype(_, "telegram_ads"), do: ExGram.Model.TransactionPartnerTelegramAds
  def subtype(_, "telegram_api"), do: ExGram.Model.TransactionPartnerTelegramApi
  def subtype(_, "other"), do: ExGram.Model.TransactionPartnerOther
end
