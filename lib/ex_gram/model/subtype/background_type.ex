defimpl ExGram.Model.Subtype, for: ExGram.Model.BackgroundType do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "fill"), do: ExGram.Model.BackgroundTypeFill
  def subtype(_, "wallpaper"), do: ExGram.Model.BackgroundTypeWallpaper
  def subtype(_, "pattern"), do: ExGram.Model.BackgroundTypePattern
  def subtype(_, "chat_theme"), do: ExGram.Model.BackgroundTypeChatTheme
end
