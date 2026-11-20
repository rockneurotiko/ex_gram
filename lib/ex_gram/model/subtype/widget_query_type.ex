defimpl ExGram.Model.Subtype, for: ExGram.Model.WidgetQueryType do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "data"), do: ExGram.Model.WidgetQueryTypeData
  def subtype(_, "sign_data"), do: ExGram.Model.WidgetQueryTypeSignData
  def subtype(_, "sent_transaction"), do: ExGram.Model.WidgetQueryTypeSentTransaction
end
