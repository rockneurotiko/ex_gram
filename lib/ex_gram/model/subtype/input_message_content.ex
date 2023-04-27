defimpl ExGram.Model.Subtype, for: ExGram.Model.InputMessageContent do
  def selector_value(_, params) do
    cond do
      params[:message_text] -> "text"
      params[:address] -> "venue"
      params[:latitude] -> "location"
      params[:first_name] -> "contact"
      params[:currency] -> "invoice"
    end
  end

  def subtype(_, "text"), do: ExGram.Model.InputTextMessageContent
  def subtype(_, "location"), do: ExGram.Model.InputLocationMessageContent
  def subtype(_, "venue"), do: ExGram.Model.InputVenueMessageContent
  def subtype(_, "contact"), do: ExGram.Model.InputContactMessageContent
  def subtype(_, "invoice"), do: ExGram.Model.InputInvoiceMessageContent
end
