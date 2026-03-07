defimpl ExGram.Model.Subtype, for: ExGram.Model.InputPaidMedia do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "photo"), do: ExGram.Model.InputPaidMediaPhoto
  def subtype(_, "video"), do: ExGram.Model.InputPaidMediaVideo
end
