defimpl ExGram.Model.Subtype, for: ExGram.Model.RichText do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "anchor"), do: ExGram.Model.RichTextAnchor
  def subtype(_, "anchor_link"), do: ExGram.Model.RichTextAnchorLink
  def subtype(_, "bank_card_number"), do: ExGram.Model.RichTextBankCardNumber
  def subtype(_, "bold"), do: ExGram.Model.RichTextBold
  def subtype(_, "bot_command"), do: ExGram.Model.RichTextBotCommand
  def subtype(_, "button"), do: ExGram.Model.RichTextButton
  def subtype(_, "cashtag"), do: ExGram.Model.RichTextCashtag
  def subtype(_, "code"), do: ExGram.Model.RichTextCode
  def subtype(_, "custom_emoji"), do: ExGram.Model.RichTextCustomEmoji
  def subtype(_, "date_time"), do: ExGram.Model.RichTextDateTime
  def subtype(_, "email_address"), do: ExGram.Model.RichTextEmailAddress
  def subtype(_, "hashtag"), do: ExGram.Model.RichTextHashtag
  def subtype(_, "italic"), do: ExGram.Model.RichTextItalic
  def subtype(_, "marked"), do: ExGram.Model.RichTextMarked
  def subtype(_, "mathematical_expression"), do: ExGram.Model.RichTextMathematicalExpression
  def subtype(_, "mention"), do: ExGram.Model.RichTextMention
  def subtype(_, "phone_number"), do: ExGram.Model.RichTextPhoneNumber
  def subtype(_, "reference"), do: ExGram.Model.RichTextReference
  def subtype(_, "reference_link"), do: ExGram.Model.RichTextReferenceLink
  def subtype(_, "spoiler"), do: ExGram.Model.RichTextSpoiler
  def subtype(_, "strikethrough"), do: ExGram.Model.RichTextStrikethrough
  def subtype(_, "subscript"), do: ExGram.Model.RichTextSubscript
  def subtype(_, "superscript"), do: ExGram.Model.RichTextSuperscript
  def subtype(_, "text_mention"), do: ExGram.Model.RichTextTextMention
  def subtype(_, "underline"), do: ExGram.Model.RichTextUnderline
  def subtype(_, "url"), do: ExGram.Model.RichTextUrl
end
