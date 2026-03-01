defimpl ExGram.Model.Subtype, for: ExGram.Model.PaidMedia do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "preview"), do: ExGram.Model.PaidMediaPreview
  def subtype(_, "photo"), do: ExGram.Model.PaidMediaPhoto
  def subtype(_, "video"), do: ExGram.Model.PaidMediaVideo
end
