if Code.ensure_loaded?(Maxwell) do
  defmodule ExGram.Adapter.Maxwell do
    @moduledoc """
    HTTP Adapter that uses Maxwell
    """

    @behaviour ExGram.Adapter

    @dialyzer {:nowarn_function, get!: 1, get!: 2, post!: 1, post!: 2, call_middleware: 1}

    use Maxwell.Builder, ~w(get post)a

    @base_url "https://api.telegram.org"

    middleware(Maxwell.Middleware.BaseUrl, ExGram.Config.get(:ex_gram, :base_url, @base_url))
    middleware(Maxwell.Middleware.Headers, %{"Content-Type" => "application/json"})
    middleware(Maxwell.Middleware.Opts, connect_timeout: 20_000, recv_timeout: 30_000)

    middleware(
      Maxwell.Middleware.Json,
      encode_func: &__MODULE__.custom_encode/1,
      decode_func: &__MODULE__.custom_decode/1
    )

    adapter(Maxwell.Adapter.Hackney)

    def custom_encode(x), do: ExGram.Encoder.encode(x)
    def custom_decode(x), do: ExGram.Encoder.decode(x, keys: :atoms)

    @impl ExGram.Adapter
    def request(verb, path, body) do
      where = where_body(verb)

      new()
      |> put_path(path)
      |> add_body(where, body)
      |> do_request(verb)
      |> post_request()
    end

    defp post_request({:ok, %Maxwell.Conn{status: status} = conn}) when status in 200..299 do
      {:ok, Maxwell.Conn.get_resp_body(conn, :result)}
    end

    defp post_request({:ok, conn}) do
      body = Maxwell.Conn.get_resp_body(conn) |> encode()
      {:error, %ExGram.Error{code: :response_status_not_match, message: body}}
    end

    defp post_request({:error, reason, conn}) do
      error = Maxwell.Error.exception({__MODULE__, reason, conn})
      {:error, %ExGram.Error{code: error.status, message: error.message}}
    end

    defp post_request({:error, reason}) do
      {:error, %ExGram.Error{code: reason}}
    end

    defp do_request(conn, verb) do
      apply(__MODULE__, verb, [conn])
    end

    defp add_body(conn, where, body) do
      apply(Maxwell.Conn, where, [conn, encode_body(body)])
    end

    defp where_body(:post), do: :put_req_body
    defp where_body(_), do: :put_query_string

    defp encode_body(body) when is_map(body) do
      body
      |> Enum.map(fn {key, value} -> {key, encode(value)} end)
      |> Enum.into(%{})
    end

    defp encode_body({:multipart, parts}) do
      {:multipart, Enum.map(parts, &encode_multipart_part/1)}
    end

    defp encode_multipart_part({:file, name, path}) do
      disposition = {"form-data", [{"name", name}, {"filename", path}]}
      {:file, path, disposition, []}
    end

    defp encode_multipart_part({:file_content, name, content, filename}) do
      disposition = {"form-data", [{"name", name}, {"filename", filename}]}
      {:file_content, content, filename, disposition, []}
    end

    defp encode_multipart_part({name, value}) do
      {name, value}
    end

    defp encode(%{__struct__: _} = x) do
      x
      |> Map.from_struct()
      |> filter_map()
      |> ExGram.Encoder.encode!()
    end

    defp encode(x) when is_map(x) or is_list(x), do: ExGram.Encoder.encode!(x)
    defp encode(x), do: x

    defp filter_map(%{__struct__: _} = m) do
      m |> Map.from_struct() |> filter_map
    end

    defp filter_map(m) when is_map(m) do
      m
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Enum.map(fn {key, value} ->
        cond do
          is_list(value) ->
            {key, Enum.map(value, &filter_map/1)}

          is_map(value) ->
            {key, filter_map(value)}

          true ->
            {key, value}
        end
      end)
      |> Enum.into(%{})
    end

    defp filter_map(m) when is_list(m), do: Enum.map(m, &filter_map/1)
    defp filter_map(m), do: m
  end
end
