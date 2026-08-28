defimpl ExGram.Model.Subtype, for: ExGram.Model.RichBlock do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "anchor"), do: ExGram.Model.RichBlockAnchor
  def subtype(_, "animation"), do: ExGram.Model.RichBlockAnimation
  def subtype(_, "audio"), do: ExGram.Model.RichBlockAudio
  def subtype(_, "blockquote"), do: ExGram.Model.RichBlockBlockQuotation
  def subtype(_, "buttons"), do: ExGram.Model.RichBlockButtons
  def subtype(_, "collage"), do: ExGram.Model.RichBlockCollage
  def subtype(_, "details"), do: ExGram.Model.RichBlockDetails
  def subtype(_, "divider"), do: ExGram.Model.RichBlockDivider
  def subtype(_, "document"), do: ExGram.Model.RichBlockDocument
  def subtype(_, "expandable_blockquote"), do: ExGram.Model.RichBlockExpandableBlockQuotation
  def subtype(_, "footer"), do: ExGram.Model.RichBlockFooter
  def subtype(_, "heading"), do: ExGram.Model.RichBlockSectionHeading
  def subtype(_, "list"), do: ExGram.Model.RichBlockList
  def subtype(_, "map"), do: ExGram.Model.RichBlockMap
  def subtype(_, "mathematical_expression"), do: ExGram.Model.RichBlockMathematicalExpression
  def subtype(_, "paragraph"), do: ExGram.Model.RichBlockParagraph
  def subtype(_, "photo"), do: ExGram.Model.RichBlockPhoto
  def subtype(_, "pre"), do: ExGram.Model.RichBlockPreformatted
  def subtype(_, "pullquote"), do: ExGram.Model.RichBlockPullQuotation
  def subtype(_, "slideshow"), do: ExGram.Model.RichBlockSlideshow
  def subtype(_, "table"), do: ExGram.Model.RichBlockTable
  def subtype(_, "thinking"), do: ExGram.Model.RichBlockThinking
  def subtype(_, "video"), do: ExGram.Model.RichBlockVideo
  def subtype(_, "voice_note"), do: ExGram.Model.RichBlockVoiceNote
end
