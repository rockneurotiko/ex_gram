defimpl ExGram.Model.Subtype, for: ExGram.Model.RevenueWithdrawalState do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "pending"), do: ExGram.Model.RevenueWithdrawalStatePending
  def subtype(_, "succeeded"), do: ExGram.Model.RevenueWithdrawalStateSucceeded
  def subtype(_, "failed"), do: ExGram.Model.RevenueWithdrawalStateFailed
end
