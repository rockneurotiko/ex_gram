# Installation

This guide covers installing ExGram and configuring its dependencies.

## Basic Installation

Add `ex_gram` and `jason` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:ex_gram, "~> 0.61"},
    {:jason, ">= 1.0.0"},
    # HTTP Adapter (see below)
  ]
end
```

After adding dependencies, run:

```bash
mix deps.get
```

## HTTP Adapter

ExGram requires an HTTP adapter to communicate with the Telegram Bot API. Choose one of the following options.

### Req Adapter (Recommended)

The [Req](https://hexdocs.pm/req) adapter is the simplest to set up and is recommended for most use cases.

**Add to deps:**

```elixir
{:req, "~> 0.5"}
```

**Add to config:**

```elixir
config :ex_gram, adapter: ExGram.Adapter.Req
```

### Tesla Adapter

[Tesla](https://hexdocs.pm/tesla) provides more flexibility and supports multiple underlying HTTP clients.

**Add to deps:**

```elixir
{:tesla, "~> 1.16"},
{:hackney, "~> 3.2"}  # Default client
```

**Add to config:**

```elixir
config :ex_gram, adapter: ExGram.Adapter.Tesla
```

#### Tesla Underlying Adapters

Tesla supports several HTTP clients. The default is Hackney, but you can use:

- **Finch** - Modern, efficient HTTP client
- **Gun** - HTTP/1.1 and HTTP/2 client
- **Mint** - Low-level HTTP client
- **Httpc** - Built into Erlang
- **Ibrowse** - Another Erlang HTTP client

**Example using Gun:**

```elixir
# In deps
{:tesla, "~> 1.16"},
{:gun, "~> 2.0"}

# In config
config :tesla, adapter: Tesla.Adapter.Gun
```

#### Tesla Logger Configuration

By default, ExGram adds `Tesla.Middleware.Logger` with log level `:info`.

You can configure the log level and other options ([Tesla Logger docs](https://hexdocs.pm/tesla/Tesla.Middleware.Logger.html#module-options)):

```elixir
config :ex_gram, Tesla.Middleware.Logger, level: :debug
```

#### Tesla Middlewares

You can add custom [Tesla middlewares](https://github.com/teamon/tesla#middleware) to ExGram:

```elixir
config :ex_gram, ExGram.Adapter.Tesla,
  middlewares: [
    {Tesla.Middleware.BaseUrl, "https://example.com/foo"}
  ]
```

For middlewares that require functions or complex configuration, define a function that returns the Tesla configuration:

```elixir
# lib/tesla_middlewares.ex
defmodule TeslaMiddlewares do
  def retry() do
    {Tesla.Middleware.Retry,
     delay: 500,
     max_retries: 10,
     max_delay: 4_000,
     should_retry: fn
       {:ok, %{status: status}} when status in [400, 500] -> true
       {:ok, _} -> false
       {:error, _} -> true
     end}
  end
end

# config/config.exs
config :ex_gram, ExGram.Adapter.Tesla,
  middlewares: [
    {TeslaMiddlewares, :retry, []}
  ]
```

The function must return a two-tuple as Tesla requires.

### Custom Adapter

You can implement your own HTTP adapter by implementing the `ExGram.Adapter` behaviour:

```elixir
config :ex_gram, adapter: YourCustomAdapter
```

## JSON Engine

By default, ExGram uses [Jason](https://hexdocs.pm/jason) for JSON encoding/decoding. You can change it to any engine that exposes `encode/2`, `encode!/2`, `decode/2`, and `decode!/2`:

```elixir
config :ex_gram, json_engine: Poison
```

## Next Steps

- [Getting Started](getting-started.md) - Create your first bot
- [Handling Updates](handling-updates.md) - Learn about different update types
- [Sending Messages](sending-messages.md) - Explore the DSL for building responses
- [Polling and Webhooks](polling-and-webhooks.md) - Configure how your bot receives updates
