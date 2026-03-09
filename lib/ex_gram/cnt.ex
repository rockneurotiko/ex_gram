defmodule ExGram.Cnt do
  @moduledoc """
  Context struct for ExGram request handling.

  The `Cnt` (context) struct flows through the entire request pipeline, carrying
  the bot name, bot info, incoming update, parsed message data, middleware state,
  and user-defined extra data.

  Middleware functions receive and return a `%ExGram.Cnt{}`, allowing them to inspect
  and modify the context. Handler callbacks defined with `ExGram.Dsl` also receive
  and return this struct.

  ## Fields

    * `:name` - Bot name (atom or binary)
    * `:bot_info` - Bot user info (`t:ExGram.Model.User.t/0`)
    * `:update` - Incoming update (`t:ExGram.Model.Update.t/0`)
    * `:message` - Parsed message data (varies by handler)
    * `:halted` - Whether the request pipeline is halted
    * `:middlewares` - Middleware configuration
    * `:middleware_halted` - Whether middleware chain is halted
    * `:commands` - Command configuration
    * `:regex` - Regex pattern configuration
    * `:answers` - Accumulated answers
    * `:responses` - Accumulated responses
    * `:extra` - User-defined data (map)

  See the [Middlewares guide](middlewares.md) for more details.
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
    Map.merge(%__MODULE__{}, extra)
  end
end
