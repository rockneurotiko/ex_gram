defimpl ExGram.Model.Subtype, for: ExGram.Model.BackgroundFill do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "solid"), do: ExGram.Model.BackgroundFillSolid
  def subtype(_, "gradient"), do: ExGram.Model.BackgroundFillGradient
  def subtype(_, "freeform_gradient"), do: ExGram.Model.BackgroundFillFreeformGradient
end
