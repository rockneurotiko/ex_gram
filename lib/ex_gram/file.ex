defmodule ExGram.File do
  @moduledoc """
  Helpers for working with Telegram file downloads.

  After retrieving file metadata with `ExGram.get_file/2`, use `file_url/2` to
  generate the download URL for the file.
  """

  @base_url "https://api.telegram.org/file"

  @doc """
  Generate the full file URL ready to be downloaded.

  ## Usage

  First, retrieve the file metadata:

      {:ok, file} = ExGram.get_file(file_id)

  Then generate the download URL:

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
