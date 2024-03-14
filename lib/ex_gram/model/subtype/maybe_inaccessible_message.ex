defimpl ExGram.Model.Subtype, for: ExGram.Model.MaybeInaccessibleMessage do
  def selector_value(_, params) do
    params.date
  end

  def subtype(_, 0), do: ExGram.Model.InaccessibleMessage
  def subtype(_, _), do: ExGram.Model.Message
end
