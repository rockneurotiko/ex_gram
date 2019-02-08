defmodule ExGram.File do
  @moduledoc """
  Helpers when dealing with telegram files
  """

  @base_url "https://api.telegram.org/file"

  @doc """
  Generate the full file URL ready to be downloaded, usage:

  First, you need to extract the File with ExGram.get_file(file_id)

  Then:

  ExGram.File.file_url(file)

  You can pass the usual `:bot` and `:token` params:

  ExGram.File.file_url(file, bot: :my_bot)
  ExGram.File.file_url(file, token: "MyBotToken")
  """
  @spec file_url(ExGram.Model.File.t(), keyword) :: String.t()
  def file_url(%ExGram.Model.File{file_path: path}, ops \\ []) do
    token = ExGram.Token.fetch(ops)
    create_url(token, path)
  end

  defp create_url(token, path) when is_binary(token) and is_binary(path),
    do: @base_url <> "/bot" <> token <> "/" <> path
end
