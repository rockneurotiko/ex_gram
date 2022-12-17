defmodule ExGram.Telemetry do
  def span(event_name \\ [], meta \\ %{}, fun) do
    event_name = [:ex_gram | event_name]

    :telemetry.span(event_name, meta, fun)
  end
end
