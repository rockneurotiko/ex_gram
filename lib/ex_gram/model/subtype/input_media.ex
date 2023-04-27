defimpl ExGram.Model.Subtype, for: ExGram.Model.InputMedia do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "photo"), do: ExGram.Model.InputMediaPhoto
  def subtype(_, "video"), do: ExGram.Model.InputMediaVideo
  def subtype(_, "animation"), do: ExGram.Model.InputMediaAnimation
  def subtype(_, "audio"), do: ExGram.Model.InputMediaAudio
  def subtype(_, "document"), do: ExGram.Model.InputMediaDocument
end
