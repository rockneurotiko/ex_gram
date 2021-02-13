defmodule ExGram.LogAdapter.JsonLogger do
  @moduledoc """
  Logs in a one line JSON, with the following format:

    {"log_level":"<log_level>","message":"<message>","time":"<time_now>"}

    - log_level -> debug, warn or error
    - message -> string provided
    - time -> date now with the following format: 2021-02-13 22:21:49.503110Z
  """

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
