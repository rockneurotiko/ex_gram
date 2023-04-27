defprotocol ExGram.Model.Subtype do
  @spec selector_value(t, map()) :: any
  def selector_value(struct, params)

  @spec subtype(t, any) :: atom()
  def subtype(struct, selector_value)
end
