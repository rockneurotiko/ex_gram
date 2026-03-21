defmodule ExGram.BotInit do
  @moduledoc """
  Behaviour for library-level bot initialization hooks.

  Modules implementing this behaviour are called once during bot startup,
  before the user's `c:ExGram.Handler.init/1` callback. Use this to set up
  storage tables, register processes, or inject data into every context.

  ## Return values

  - `:ok` - hook succeeded, no extra data
  - `{:ok, map()}` - hook succeeded, merge map into `extra_info`
    (which flows into every `ExGram.Cnt.extra`)
  - `{:error, reason}` - hook failed, **the bot will not start**

  ## Registration

  Register hooks in your bot module using the `on_bot_init/1-2` macro
  (available via `use ExGram.Bot`):

      defmodule MyBot do
        use ExGram.Bot, name: :my_bot

        on_bot_init(MyLibrary.Initializer, some_opt: :value)
        # ...
      end

  Libraries that provide a `use` macro should emit `on_bot_init/1-2` calls
  automatically, so end-users don't need to wire anything manually.

  ## Execution order

  Hooks run in declaration order, before the user's `c:ExGram.Handler.init/1`
  callback. Each hook receives the accumulated `extra_info` from all previous
  hooks via the `extra_info:` key in `init_opts`.
  """

  @type init_opts :: [bot: atom(), token: String.t(), extra_info: map()]

  @callback on_bot_init(init_opts()) :: :ok | {:ok, map()} | {:error, any()}
end
