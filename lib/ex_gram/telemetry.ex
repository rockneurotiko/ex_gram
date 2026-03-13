defmodule ExGram.Telemetry do
  @moduledoc """
  Telemetry integration for ExGram.

  ExGram emits telemetry events at key points in its lifecycle. You can attach
  handlers to these events for logging, metrics, and tracing.

  All durations are in `:native` time units. Use `System.convert_time_unit/3` to
  convert to milliseconds:

      System.convert_time_unit(duration, :native, :millisecond)

  ## Quick start

      :telemetry.attach_many(
        "my-app-ex-gram-handler",
        [
          [:ex_gram, :request, :start],
          [:ex_gram, :request, :stop],
          [:ex_gram, :request, :exception],
          [:ex_gram, :update, :start],
          [:ex_gram, :update, :stop],
          [:ex_gram, :handler, :start],
          [:ex_gram, :handler, :stop],
          [:ex_gram, :handler, :exception],
        ],
        &MyApp.Telemetry.handle_event/4,
        nil
      )

  ## Events

  ### `[:ex_gram, :request, :start | :stop | :exception]`

  Emitted around every outbound Telegram Bot API call (e.g. `sendMessage`,
  `getUpdates`, `answerCallbackQuery`). This covers all calls made through the
  ExGram API, whether from DSL helpers or direct calls.

  #### `:start` measurements

  | Key | Type | Description |
  |-----|------|-------------|
  | `:system_time` | integer | `System.system_time/0` at start |
  | `:monotonic_time` | integer | `System.monotonic_time/0` at start |

  #### `:start` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:method` | `String.t()` | Telegram API method name, e.g. `"sendMessage"` |
  | `:request_type` | atom | HTTP verb - `:get` or `:post` |
  | `:body` | map | Request parameters (token is excluded) |
  | `:bot` | atom or nil | Bot name from the `bot:` option, or `nil` |

  #### `:stop` measurements

  | Key | Type | Description |
  |-----|------|-------------|
  | `:duration` | integer | Elapsed time in `:native` units |

  #### `:stop` metadata

  All `:start` metadata, plus:

  | Key | Type | Description |
  |-----|------|-------------|
  | `:result` | `{:ok, term} \| {:error, ExGram.Error.t()}` | API call result |

  #### `:exception` measurements

  | Key | Type | Description |
  |-----|------|-------------|
  | `:duration` | integer | Elapsed time in `:native` units |

  #### `:exception` metadata

  All `:start` metadata, plus:

  | Key | Type | Description |
  |-----|------|-------------|
  | `:kind` | atom | `:error`, `:exit`, or `:throw` |
  | `:reason` | term | The exception or reason |
  | `:stacktrace` | list | Stacktrace |

  ---

  ### `[:ex_gram, :update, :start | :stop | :exception]`

  Emitted around the processing of each incoming Telegram update - from the
  moment it arrives at the dispatcher through middleware execution. Handler
  execution is measured separately by the `[:ex_gram, :handler, ...]` events.

  Note: when using async dispatch (the default), the `:stop` event fires after
  middlewares complete and the handler process is spawned - not after the handler
  finishes. Use `[:ex_gram, :handler, ...]` events to measure handler duration.

  #### `:start` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:update` | `ExGram.Model.Update.t()` | The incoming Telegram update |

  #### `:stop` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:context` | `ExGram.Cnt.t()` | Context after middleware processing |
  | `:halted` | boolean | Whether middleware halted processing |

  #### `:exception` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:update` | `ExGram.Model.Update.t()` | The incoming update |
  | `:kind` | atom | `:error`, `:exit`, or `:throw` |
  | `:reason` | term | The exception or reason |
  | `:stacktrace` | list | Stacktrace |

  ---

  ### `[:ex_gram, :handler, :start | :stop | :exception]`

  Emitted around the invocation of the bot's `handle/2` callback.

  #### `:start` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:handler` | module | The handler module (e.g. `MyApp.Bot`) |
  | `:context` | `ExGram.Cnt.t()` | Context passed to the handler |

  #### `:stop` metadata

  All `:start` metadata, plus:

  | Key | Type | Description |
  |-----|------|-------------|
  | `:result_context` | `ExGram.Cnt.t() \| term` | Return value of `handle/2` |

  #### `:exception` metadata

  All `:start` metadata, plus `:kind`, `:reason`, `:stacktrace`.

  ---

  ### `[:ex_gram, :middleware, :start | :stop | :exception]`

  Emitted around the execution of each individual middleware in the pipeline.

  #### `:start` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:middleware` | module or function | The middleware being executed |
  | `:context` | `ExGram.Cnt.t()` | Context entering the middleware |

  #### `:stop` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:middleware` | module or function | The middleware that was executed |
  | `:context` | `ExGram.Cnt.t()` | Context after middleware execution |
  | `:halted` | boolean | Whether this middleware halted or middleware-halted the pipeline |

  #### `:exception` metadata

  All `:start` metadata, plus `:kind`, `:reason`, `:stacktrace`.

  ---

  ### `[:ex_gram, :polling, :start | :stop | :exception]`

  Emitted around each polling cycle - the fetch-and-dispatch loop that retrieves
  updates from the Telegram Bot API.

  #### `:start` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |

  #### `:stop` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:updates_count` | non_neg_integer | Number of updates received in this cycle |

  #### `:exception` metadata

  | Key | Type | Description |
  |-----|------|-------------|
  | `:bot` | atom | Bot name |
  | `:kind` | atom | `:error`, `:exit`, or `:throw` |
  | `:reason` | term | The exception or reason |
  | `:stacktrace` | list | Stacktrace |
  """

  @doc false
  def start(event, meta \\ %{}, extra_measurements \\ %{}) do
    start_time = System.monotonic_time()

    measurements =
      Map.merge(
        %{system_time: System.system_time(), monotonic_time: start_time},
        extra_measurements
      )

    :telemetry.execute([:ex_gram | List.wrap(event)] ++ [:start], measurements, meta)

    start_time
  end

  @doc false
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()

    measurements =
      Map.merge(
        %{duration: end_time - start_time},
        extra_measurements
      )

    :telemetry.execute([:ex_gram | List.wrap(event)] ++ [:stop], measurements, meta)
  end

  @doc false
  def exception(event, start_time, kind, reason, stack, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()

    measurements =
      Map.merge(
        %{duration: end_time - start_time},
        extra_measurements
      )

    meta =
      Map.merge(meta, %{
        kind: kind,
        reason: reason,
        stacktrace: stack
      })

    :telemetry.execute([:ex_gram | List.wrap(event)] ++ [:exception], measurements, meta)
  end

  @doc false
  def span(event, start_metadata, fun) do
    :telemetry.span([:ex_gram | List.wrap(event)], start_metadata, fun)
  end
end
