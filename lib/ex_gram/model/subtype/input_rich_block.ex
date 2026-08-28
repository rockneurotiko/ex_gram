defimpl ExGram.Model.Subtype, for: ExGram.Model.InputRichBlock do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "anchor"), do: ExGram.Model.InputRichBlockAnchor
  def subtype(_, "animation"), do: ExGram.Model.InputRichBlockAnimation
  def subtype(_, "audio"), do: ExGram.Model.InputRichBlockAudio
  def subtype(_, "blockquote"), do: ExGram.Model.InputRichBlockBlockQuotation
  def subtype(_, "buttons"), do: ExGram.Model.InputRichBlockButtons
  def subtype(_, "collage"), do: ExGram.Model.InputRichBlockCollage
  def subtype(_, "details"), do: ExGram.Model.InputRichBlockDetails
  def subtype(_, "divider"), do: ExGram.Model.InputRichBlockDivider
  def subtype(_, "document"), do: ExGram.Model.InputRichBlockDocument
  def subtype(_, "expandable_blockquote"), do: ExGram.Model.InputRichBlockExpandableBlockQuotation
  def subtype(_, "footer"), do: ExGram.Model.InputRichBlockFooter
  def subtype(_, "heading"), do: ExGram.Model.InputRichBlockSectionHeading
  def subtype(_, "list"), do: ExGram.Model.InputRichBlockList
  def subtype(_, "map"), do: ExGram.Model.InputRichBlockMap
  def subtype(_, "mathematical_expression"), do: ExGram.Model.InputRichBlockMathematicalExpression
  def subtype(_, "paragraph"), do: ExGram.Model.InputRichBlockParagraph
  def subtype(_, "photo"), do: ExGram.Model.InputRichBlockPhoto
  def subtype(_, "pre"), do: ExGram.Model.InputRichBlockPreformatted
  def subtype(_, "pullquote"), do: ExGram.Model.InputRichBlockPullQuotation
  def subtype(_, "slideshow"), do: ExGram.Model.InputRichBlockSlideshow
  def subtype(_, "table"), do: ExGram.Model.InputRichBlockTable
  def subtype(_, "thinking"), do: ExGram.Model.InputRichBlockThinking
  def subtype(_, "video"), do: ExGram.Model.InputRichBlockVideo
  def subtype(_, "voice_note"), do: ExGram.Model.InputRichBlockVoiceNote
end
