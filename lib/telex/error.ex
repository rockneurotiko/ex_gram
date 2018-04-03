defmodule Telex.Error do
  @type t :: %__MODULE__{code: number, message: String.t() | nil}
  defexception [:code, :message]
end
