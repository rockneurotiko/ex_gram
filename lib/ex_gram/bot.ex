defmodule ExGram.Bot do
  @moduledoc """
  Bot creation helper.

  Usage:

  - Create one or more bots

  ``` elixir
  defmodule MyBot do
    use ExGram.Bot, name: :my_bot, setup_commands: true

    command("echo", description: "Echo the message back to the user")

    middleware(ExGram.Middleware.IgnoreUsername)

    # Command received as `:echo` instead of `"echo"` because it was configured as a command before
    def handle({:command, :echo, %{text: t}}, cnt) do
      cnt |> answer(t)
    end

    def handle(msg, _cnt) do
      IO.puts("Unknown message " <> inspect(msg))
    end
  end
  ```

  - Add `ExGram` and your bots to your application children

  ``` elixir
  children = [
    # ...
    ExGram,
    {MyBot, [method: :polling, token: "bot_token"]}
  ]
  ```
  """
  alias ExGram.Cnt

  @type middleware_fn() :: (Cnt.t(), opts :: any() -> Cnt.t())
  @type middleware() :: {module() | middleware_fn(), opts :: any()}

  defmacro __using__(opts) do
    name = Keyword.get(opts, :name) || raise ArgumentError, "name parameter is mandatory"
    module_opts = Keyword.take(opts, [:username, :setup_commands])

    quote location: :keep do
      @behaviour ExGram.Handler

      use ExGram.Middleware.Builder

      import ExGram.Dsl

      @doc """
Returns the configured bot name for this module.
"""
@spec name() :: atom() | String.t()
def name, do: unquote(name)

      @doc """
      Builds the supervision child specification for the bot by merging the module's default options with the provided `opts`.
      
      ## Parameters
      
        - opts: Keyword list of runtime options to override or extend the module defaults (for example `:token` or `:bot`).
      
      ## Examples
      
          MyBot.child_spec(token: "TOKEN")
      
      """
      @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
      def child_spec(opts) do
        opts = Keyword.merge(unquote(module_opts), opts)
        ExGram.Bot.Supervisor.child_spec(opts, __MODULE__)
      end

      @doc """
      Starts and links the bot supervisor process using the provided options merged with the module's configured options.
      
      ## Parameters
      
        - opts: Keyword list of runtime options to configure the bot; these are merged with the module's compile-time options.
      """
      @spec start_link(Keyword.t()) :: {:ok, pid()} | {:error, term()}
      def start_link(opts) do
        opts = Keyword.merge(unquote(module_opts), opts)
        ExGram.Bot.Supervisor.start_link(opts, __MODULE__)
      end

      @impl ExGram.Handler
      @doc """
      Performs default bot initialization and ignores any provided options.
      
      ## Parameters
      
        - _opts: Initialization options (ignored).
      
      ## Returns
      
        - `:ok` indicating successful initialization.
      """
      @spec init(any()) :: :ok
      def init(_opts) do
        :ok
      end

      def message(from, message) do
        GenServer.call(name(), {:message, from, message})
      end

      # Default implementations

      @impl ExGram.Handler
      def handle(msg, _cnt) do
        handle_error(%ExGram.Error{
          code: :not_handled,
          message: "Message not handled: #{inspect(msg)}"
        })
      end

      @impl ExGram.Handler
      @doc """
      Passes an error through unchanged.
      """
      @spec handle_error(term()) :: term()
      def handle_error(error) do
        error
      end

      defoverridable ExGram.Handler
    end
  end
end
