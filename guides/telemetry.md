# Telemetry

ExGram emits [`:telemetry`](https://hexdocs.pm/telemetry) events at key points
in its lifecycle, letting you integrate with any observability tool that speaks
the `:telemetry` protocol - including Prometheus (via
[`TelemetryMetrics`](https://hexdocs.pm/telemetry_metrics)),
[`OpenTelemetry`](https://opentelemetry.io/), or simple structured logging.

## Events overview

| Event | Description |
|---|---|
| `[:ex_gram, :request, :start\|:stop\|:exception]` | Outbound Telegram API call |
| `[:ex_gram, :update, :start\|:stop\|:exception]` | Incoming update dispatched to the bot |
| `[:ex_gram, :handler, :start\|:stop\|:exception]` | Your `handle/2` callback invocation |
| `[:ex_gram, :middleware, :start\|:stop\|:exception]` | Each middleware in the pipeline |
| `[:ex_gram, :polling, :start\|:stop\|:exception]` | One polling cycle (fetch + dispatch) |

All durations are in `:native` time units. Convert to milliseconds with:

```elixir
System.convert_time_unit(duration, :native, :millisecond)
```

See `ExGram.Telemetry` for the full metadata reference for each event.

## Attaching handlers

Use `:telemetry.attach/4` (one event) or `:telemetry.attach_many/4` (multiple
events) to subscribe. A handler is a 4-arity function:
`(event_name, measurements, metadata, config) -> any`.

```elixir
defmodule MyApp.Telemetry do
  require Logger

  def setup do
    :telemetry.attach_many(
      "my-app-ex-gram",
      [
        [:ex_gram, :request, :start],
        [:ex_gram, :request, :stop],
        [:ex_gram, :request, :exception],
        [:ex_gram, :update, :start],
        [:ex_gram, :update, :stop],
        [:ex_gram, :handler, :start],
        [:ex_gram, :handler, :stop],
        [:ex_gram, :handler, :exception],
        [:ex_gram, :middleware, :start],
        [:ex_gram, :middleware, :stop],
        [:ex_gram, :polling, :start],
        [:ex_gram, :polling, :stop],
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, metadata, _config) do
    Logger.debug("Telemetry: #{inspect(event)} #{inspect(measurements)} #{inspect(metadata)}")
  end
end
```

Call `MyApp.Telemetry.setup/0` in your `Application.start/2` before starting
your supervision tree.

## Logging API requests

Log every outbound Telegram API call with its duration and result:

```elixir
def handle_event([:ex_gram, :request, :stop], measurements, metadata, _) do
  duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

  case metadata.result do
    {:ok, _} ->
      Logger.info("[ExGram] #{metadata.method} OK in #{duration_ms}ms bot=#{metadata.bot}")

    {:error, error} ->
      Logger.warning(
        "[ExGram] #{metadata.method} ERROR in #{duration_ms}ms " <>
          "code=#{error.code} message=#{error.message} bot=#{metadata.bot}"
      )
  end
end

def handle_event([:ex_gram, :request, :exception], measurements, metadata, _) do
  duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

  Logger.error(
    "[ExGram] #{metadata.method} EXCEPTION in #{duration_ms}ms " <>
      "kind=#{metadata.kind} reason=#{inspect(metadata.reason)} bot=#{metadata.bot}"
  )
end
```

## Tracking update processing latency

Measure the full pipeline (middleware + routing) for each update:

```elixir
def handle_event([:ex_gram, :update, :stop], measurements, metadata, _) do
  duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

  Logger.info(
    "[ExGram] update processed in #{duration_ms}ms " <>
      "bot=#{metadata.bot} halted=#{metadata.halted}"
  )
end
```

## Alerting on handler exceptions

The `[:ex_gram, :handler, :exception]` event fires when your `handle/2`
callback raises. Use it to alert or capture errors:

```elixir
def handle_event([:ex_gram, :handler, :exception], _measurements, metadata, _) do
  Logger.error(
    "[ExGram] handler raised in bot=#{metadata.bot} " <>
      "handler=#{metadata.handler} kind=#{metadata.kind} " <>
      "reason=#{inspect(metadata.reason)}"
  )

  # Forward to your error tracker (e.g. Sentry, Honeybadger)
  # Sentry.capture_exception(metadata.reason, stacktrace: metadata.stacktrace)
end
```

## Prometheus metrics with `telemetry_metrics`

Add `{:telemetry_metrics, "~> 1.0"}` and `{:telemetry_poller, "~> 1.0"}` to
your app's deps, then define metrics:

```elixir
defmodule MyApp.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      # Count every API call
      counter("ex_gram.request.stop.count",
        tags: [:method, :bot]
      ),

      # Distribution of API call durations
      distribution("ex_gram.request.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :bot],
        reporter_options: [buckets: [10, 50, 100, 500, 1000, 5000]]
      ),

      # Count API errors
      counter("ex_gram.request.stop.error_count",
        keep: &match?({:error, _}, &1.result),
        tags: [:method, :bot]
      ),

      # Count incoming updates
      counter("ex_gram.update.stop.count",
        tags: [:bot]
      ),

      # Distribution of update processing time
      distribution("ex_gram.update.stop.duration",
        unit: {:native, :millisecond},
        tags: [:bot]
      ),

      # Count handler exceptions
      counter("ex_gram.handler.exception.count",
        tags: [:bot, :handler]
      ),

      # Distribution of polling cycle durations
      distribution("ex_gram.polling.stop.duration",
        unit: {:native, :millisecond},
        tags: [:bot]
      ),
    ]
  end
end
```

## Middleware timing

If your bot has multiple middlewares, you can measure each one individually:

```elixir
def handle_event([:ex_gram, :middleware, :stop], measurements, metadata, _) do
  duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

  Logger.debug(
    "[ExGram] middleware #{inspect(metadata.middleware)} in #{duration_ms}ms " <>
      "bot=#{metadata.bot} halted=#{metadata.halted}"
  )
end
```

## Handler vs. update events

It is worth understanding the distinction between update and handler events:

- **`[:ex_gram, :update, ...]`** - spans middleware execution and update routing.
  When using async dispatch (the default), the stop event fires after the handler
  _process is spawned_, not after the handler finishes. The duration reflects
  middleware + routing overhead only.

- **`[:ex_gram, :handler, ...]`** - spans the actual `handle/2` callback. This
  event always fires in the process executing the handler (the spawned process
  for async dispatch, or the GenServer process for sync dispatch).

For end-to-end latency tracking, subscribe to `[:ex_gram, :handler, :stop]`.
