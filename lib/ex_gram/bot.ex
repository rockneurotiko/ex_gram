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

  - Add ExGram and your bots to your application childrens

  ``` elixir
  children = [
    # ...
    ExGram,
    {MyBot, [method: :polling, token: "bot_token]}
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

      def name, do: unquote(name)

      def child_spec(opts) do
        opts = Keyword.merge(opts, unquote(module_opts))
        ExGram.Bot.Supervisor.child_spec(opts, __MODULE__)
      end

      @type init_opts :: [bot: atom() | String.t(), token: String.t()]
      @spec init(init_opts) :: :ok
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
      def handle_error(error) do
        error
      end

      defoverridable ExGram.Handler
      defoverridable init: 1
    end
  end
end
