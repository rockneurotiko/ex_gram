if Code.ensure_loaded?(OpenTelemetry.Ctx) do
  defmodule OpentelemetryExGram.Propagator do
    @moduledoc """
    Captures and attaches OpenTelemetry context across process boundaries.

    This module provides helpers that allow the OTel context to survive GenServer
    calls, casts, and `spawn/1` boundaries inside ExGram's internal pipeline.

    When `opentelemetry_api` is not available, all functions in this module are
    no-ops compiled at build time, so there is zero runtime overhead.
    """

    @doc """
    Captures the current OpenTelemetry context from the calling process dictionary.

    Returns the current OTel context, which can be passed to another process and
    restored with `attach_ctx/1`.
    """
    @spec capture_ctx() :: OpenTelemetry.Ctx.t()
    def capture_ctx do
      OpenTelemetry.Ctx.get_current()
    end

    @doc """
    Attaches a previously captured OpenTelemetry context to the current process.

    This is a no-op when `ctx` is `:undefined` or `nil` (e.g. when no OTel context
    was active when `capture_ctx/0` was called).
    """
    @spec attach_ctx(OpenTelemetry.Ctx.t() | :undefined | nil) :: :ok
    def attach_ctx(ctx) when ctx != :undefined and not is_nil(ctx) do
      OpenTelemetry.Ctx.attach(ctx)
      :ok
    end

    def attach_ctx(_), do: :ok

    @doc """
    Spawns a new process with the current OpenTelemetry context propagated.

    Captures the current OTel context before spawning, then attaches it inside
    the new process before calling `fun`. This ensures the spawned process
    inherits the active trace and span.

    ## Example

        OpentelemetryExGram.Propagator.spawn(fn ->
          do_some_traced_work()
        end)
    """
    @spec spawn((-> any())) :: pid()
    def spawn(fun) when is_function(fun, 0) do
      ctx = capture_ctx()

      Kernel.spawn(fn ->
        attach_ctx(ctx)
        fun.()
      end)
    end
  end
else
  defmodule OpentelemetryExGram.Propagator do
    @moduledoc """
    No-op implementation of `OpentelemetryExGram.Propagator`.

    This version is compiled when `opentelemetry_api` is not available.
    All functions are no-ops with zero overhead.

    Add `{:opentelemetry_api, "~> 1.2"}` to your dependencies to enable
    OpenTelemetry context propagation.
    """

    @doc false
    @spec capture_ctx() :: :undefined
    def capture_ctx, do: :undefined

    @doc false
    @spec attach_ctx(any()) :: :ok
    def attach_ctx(_ctx), do: :ok

    @doc false
    @spec spawn((-> any())) :: pid()
    def spawn(fun) when is_function(fun, 0), do: Kernel.spawn(fun)
  end
end
