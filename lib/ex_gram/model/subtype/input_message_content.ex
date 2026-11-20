defimpl ExGram.Model.Subtype, for: ExGram.Model.InputMessageContent do
  def selector_value(_, params) do
    cond do
      params[:rich_message] -> "rich"
      params[:message_text] -> "text"
      params[:address] -> "venue"
      params[:latitude] -> "location"
      params[:first_name] -> "contact"
      params[:currency] -> "invoice"
      params[:html] -> "widget"
      params[:widget_id] -> "shared_widget"
    end
  end

  def subtype(_, "text"), do: ExGram.Model.InputTextMessageContent
  def subtype(_, "rich"), do: ExGram.Model.InputRichMessageContent
  def subtype(_, "location"), do: ExGram.Model.InputLocationMessageContent
  def subtype(_, "venue"), do: ExGram.Model.InputVenueMessageContent
  def subtype(_, "contact"), do: ExGram.Model.InputContactMessageContent
  def subtype(_, "invoice"), do: ExGram.Model.InputInvoiceMessageContent
  def subtype(_, "widget"), do: ExGram.Model.InputWidgetMessageContent
  def subtype(_, "shared_widget"), do: ExGram.Model.InputSharedWidgetMessageContent
end
