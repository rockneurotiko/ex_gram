defmodule ExGram.Middleware.IgnoreUsername do
  use ExGram.Middleware

  alias ExGram.Cnt

  def call(
        %Cnt{
          bot_info: %{username: username},
          update: %{message: %{text: t} = message} = update
        } = cnt,
        _opts
      )
      when is_binary(username) and is_binary(t) do
    new_text = clean_command(t, username)
    new_msg = %{message | text: new_text}
    new_update = %{update | message: new_msg}
    %{cnt | update: new_update}
  end

  def call(cnt, _), do: cnt

  defp clean_command("/" <> text, username) do
    [raw_command | rest] = String.split(text, " ")

    cmd =
      case String.split(raw_command, "@") do
        [command, ^username] -> "/" <> command
        _ -> "/" <> raw_command
      end

    [cmd | rest] |> Enum.join(" ")
  end

  defp clean_command(text, _username), do: text
end
