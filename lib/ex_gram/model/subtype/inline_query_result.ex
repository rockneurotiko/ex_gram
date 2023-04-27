defimpl ExGram.Model.Subtype, for: ExGram.Model.InlineQueryResult do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "article"), do: ExGram.Model.InlineQueryResultArticle
  def subtype(_, "audio"), do: ExGram.Model.InlineQueryResultAudio
  def subtype(_, "contact"), do: ExGram.Model.InlineQueryResultContact
  def subtype(_, "game"), do: ExGram.Model.InlineQueryResultGame
  def subtype(_, "document"), do: ExGram.Model.InlineQueryResultDocument
  def subtype(_, "gif"), do: ExGram.Model.InlineQueryResultGif
  def subtype(_, "location"), do: ExGram.Model.InlineQueryResultLocation
  def subtype(_, "mpeg4_gif"), do: ExGram.Model.InlineQueryResultMpeg4Gif
  def subtype(_, "photo"), do: ExGram.Model.InlineQueryResultPhoto
  def subtype(_, "venue"), do: ExGram.Model.InlineQueryResultVenue
  def subtype(_, "video"), do: ExGram.Model.InlineQueryResultVideo
  def subtype(_, "voice"), do: ExGram.Model.InlineQueryResultVoice

  # TODO use custom fields to differentiate between normal & cached

  # def subtype(_, "audio"), do: ExGram.Model.InlineQueryResultCachedAudio
  # def subtype(_, "document"), do: ExGram.Model.InlineQueryResultCachedDocument
  # def subtype(_, "gif"), do: ExGram.Model.InlineQueryResultCachedGif
  # def subtype(_, "mpeg4_gif"), do: ExGram.Model.InlineQueryResultCachedMpeg4Gif
  # def subtype(_, "photo"), do: ExGram.Model.InlineQueryResultCachedPhoto
  # def subtype(_, "sticker"), do: ExGram.Model.InlineQueryResultCachedSticker
  # def subtype(_, "video"), do: ExGram.Model.InlineQueryResultCachedVideo
  # def subtype(_, "voice"), do: ExGram.Model.InlineQueryResultCachedVoice
end
