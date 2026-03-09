defmodule ExGram.Error do
  @moduledoc """
  Error struct for representing errors in ExGram.

  Can represent both errors returned by Telegram (API errors with codes and descriptions)
  and errors that occur within the library itself.

  Implements the `Exception` behaviour.
  """
  @type t :: %__MODULE__{code: number | atom, message: String.t() | any, metadata: any}
  defexception [:code, :message, :metadata]
end
