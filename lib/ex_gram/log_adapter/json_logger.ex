defmodule ExGram.LogAdapter.JsonLogger do
  @behaviour ExGram.LogAdapter

  for log_level <- [:debug, :warn, :error] do
    def unquote(log_level)(message),
      do:
        %{
          time: DateTime.now!("Etc/UTC") |> DateTime.to_string(),
          log_level: unquote(log_level),
          message: message
        }
        |> Jason.encode!()
        |> IO.puts()
  end
end
