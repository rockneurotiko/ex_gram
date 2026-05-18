defimpl ExGram.Model.Subtype, for: ExGram.Model.InputPollMedia do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "animation"), do: ExGram.Model.InputMediaAnimation
  def subtype(_, "audio"), do: ExGram.Model.InputMediaAudio
  def subtype(_, "document"), do: ExGram.Model.InputMediaDocument
  def subtype(_, "live_photo"), do: ExGram.Model.InputMediaLivePhoto
  def subtype(_, "location"), do: ExGram.Model.InputMediaLocation
  def subtype(_, "photo"), do: ExGram.Model.InputMediaPhoto
  def subtype(_, "venue"), do: ExGram.Model.InputMediaVenue
  def subtype(_, "video"), do: ExGram.Model.InputMediaVideo
end
