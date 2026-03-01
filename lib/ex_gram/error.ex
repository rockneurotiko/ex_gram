defmodule ExGram.Error do
  @moduledoc """
  Struct for representing errors in ExGram. It can be used to represent both errors returned by Telegram and errors that occur within the library itself.
  """
  @type t :: %__MODULE__{code: number | atom, message: String.t() | any, metadata: any}
  defexception [:code, :message, :metadata]
end
