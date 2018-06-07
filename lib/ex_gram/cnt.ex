defmodule ExGram.Cnt do
  @moduledoc """
  Context module for ExGram!
  """
  @type name :: atom | binary

  @type t :: %__MODULE__{
          name: name,
          bot_info: ExGram.Model.User.t() | nil,
          update: ExGram.Model.Update.t() | nil,
          message: any | nil,
          halted: boolean,
          middlewares: list(any),
          middleware_halted: boolean,
          commands: list(any),
          regex: list(any),
          answers: list(any),
          responses: list(any),
          extra: map
        }

  defstruct name: nil,
            bot_info: nil,
            update: nil,
            message: nil,
            halted: false,
            middlewares: [],
            middleware_halted: false,
            commands: [],
            regex: [],
            answers: [],
            responses: [],
            extra: %{}

  def new(extra \\ %{}) do
    %__MODULE__{} |> Map.merge(extra)
  end
end
