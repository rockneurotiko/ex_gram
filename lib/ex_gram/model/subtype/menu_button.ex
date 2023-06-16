defimpl ExGram.Model.Subtype, for: ExGram.Model.MenuButton do
  def selector_value(_, params) do
    params.type
  end

  def subtype(_, "commands"), do: ExGram.Model.MenuButtonCommands
  def subtype(_, "web_app"), do: ExGram.Model.MenuButtonWebApp
  def subtype(_, "default"), do: ExGram.Model.MenuButtonDefault
end
