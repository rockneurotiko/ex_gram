defimpl ExGram.Model.Subtype, for: ExGram.Model.InputProfilePhoto do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "static"), do: ExGram.Model.InputProfilePhotoStatic
  def subtype(_, "animated"), do: ExGram.Model.InputProfilePhotoAnimated
end
