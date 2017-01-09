defmodule Telex.Middleware do
  use Maxwell.Middleware

  @baseurl "/bot"

  def init(token), do: token

  def request(conn, token) do
    path = conn.path
    path = if (String.starts_with?(path, "/")), do: path, else: "/#{path}"
    npath = "#{@baseurl}#{token}#{path}"
    %{conn | path: npath}
  end
end
