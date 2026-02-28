defimpl ExGram.Model.Subtype, for: ExGram.Model.InputStoryContent do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "photo"), do: ExGram.Model.InputStoryContentPhoto
  def subtype(_, "video"), do: ExGram.Model.InputStoryContentVideo
end
