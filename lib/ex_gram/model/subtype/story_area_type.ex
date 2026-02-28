defimpl ExGram.Model.Subtype, for: ExGram.Model.StoryAreaType do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "location"), do: ExGram.Model.StoryAreaTypeLocation
  def subtype(_, "suggested_reaction"), do: ExGram.Model.StoryAreaTypeSuggestedReaction
  def subtype(_, "link"), do: ExGram.Model.StoryAreaTypeLink
  def subtype(_, "weather"), do: ExGram.Model.StoryAreaTypeWeather
  def subtype(_, "unique_gift"), do: ExGram.Model.StoryAreaTypeUniqueGift
end
