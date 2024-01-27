defmodule ExGram.Error do
  @moduledoc false

  @type t :: %__MODULE__{code: number | atom, message: String.t() | any, metadata: any}
  defexception [:code, :message, :metadata]
end
