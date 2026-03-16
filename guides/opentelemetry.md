# OpenTelemetry

ExGram emits [`:telemetry` events](telemetry.md) for update processing, handler execution, middleware, outbound API requests, and polling cycles. The [`opentelemetry_ex_gram`](https://github.com/rockneurotiko/opentelemetry_ex_gram) library attaches to those events and creates OpenTelemetry spans automatically.

## Installation

Add the library and the OTel SDK to your `mix.exs`:

```elixir
def deps do
  [
    {:opentelemetry_ex_gram, "~> 0.1"},
    {:opentelemetry, "~> 1.3"}
  ]
end
```

`opentelemetry_api`, `opentelemetry_telemetry`, and `opentelemetry_process_propagator` are pulled in as transitive dependencies.

## Setup

Call `OpentelemetryExGram.setup/1` once during application startup, before your bots are started:

```elixir
def start(_type, _args) do
  OpentelemetryExGram.setup()

  children = [ExGram, {MyBot, [method: :polling, token: token]}]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Available options:

| Option | Default | Description |
|---|---|---|
| `:span_prefix` | `"ExGram"` | Prefix for all span names |
| `:trace_polling` | `true` | Create spans for polling cycles |
| `:trace_middlewares` | `true` | Create spans for each middleware |
| `:trace_requests` | `true` | Create spans for outbound Telegram API calls |

## Span hierarchy

A typical update produces this span tree:

```text
{prefix}.update
  {prefix}.middleware   (one per middleware)
  {prefix}.handler
    {prefix}.request    (one per outbound API call)
```

OTel context is propagated automatically across all process boundaries, including async handlers.

## Testing

`OpentelemetryExGram.Test` provides a per-test setup helper that attaches the telemetry handler for a specific test bot and registers automatic cleanup:

```elixir
setup context do
  {bot_name, _} = ExGram.Test.start_bot(context, MyBot)
  OpentelemetryExGram.Test.setup(bot_name)
  {:ok, bot_name: bot_name}
end
```

> #### More information {: .info}
>
> For full documentation — span attributes, advanced options, and testing with
> [`opentelemetry_test_processor`](https://hex.pm/packages/opentelemetry_test_processor) — see the
> [`opentelemetry_ex_gram` repository](https://github.com/rockneurotiko/opentelemetry_ex_gram).
