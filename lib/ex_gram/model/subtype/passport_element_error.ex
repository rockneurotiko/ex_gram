defimpl ExGram.Model.Subtype, for: ExGram.Model.PassportElementError do
  def selector_value(_, params) do
    params.source
  end

  def subtype(_, "data"), do: ExGram.Model.PassportElementErrorDataField
  def subtype(_, "front_side"), do: ExGram.Model.PassportElementErrorFrontSide
  def subtype(_, "reverse_side"), do: ExGram.Model.PassportElementErrorReverseSide
  def subtype(_, "selfie"), do: ExGram.Model.PassportElementErrorSelfie
  def subtype(_, "file"), do: ExGram.Model.PassportElementErrorFile
  def subtype(_, "files"), do: ExGram.Model.PassportElementErrorFiles
  def subtype(_, "translation_file"), do: ExGram.Model.PassportElementErrorTranslationFile
  def subtype(_, "translation_files"), do: ExGram.Model.PassportElementErrorTranslationFiles
  def subtype(_, "unspecified"), do: ExGram.Model.PassportElementErrorUnspecified
end
