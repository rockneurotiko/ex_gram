defimpl ExGram.Model.Subtype, for: ExGram.Model.InputPollOptionMedia do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "animation"), do: ExGram.Model.InputMediaAnimation
  def subtype(_, "live_photo"), do: ExGram.Model.InputMediaLivePhoto
  def subtype(_, "location"), do: ExGram.Model.InputMediaLocation
  def subtype(_, "photo"), do: ExGram.Model.InputMediaPhoto
  def subtype(_, "sticker"), do: ExGram.Model.InputMediaSticker
  def subtype(_, "venue"), do: ExGram.Model.InputMediaVenue
  def subtype(_, "video"), do: ExGram.Model.InputMediaVideo
end
