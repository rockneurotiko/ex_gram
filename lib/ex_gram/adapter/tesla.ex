if Code.ensure_loaded?(Tesla) do
  defmodule ExGram.Adapter.Tesla do
    @moduledoc """
    HTTP Adapter that uses Tesla
    """

    @behaviour ExGram.Adapter

    use Tesla, only: ~w(get post)a

    @base_url "https://api.telegram.org"

    require Logger

    plug(Tesla.Middleware.BaseUrl, ExGram.Config.get(:ex_gram, :base_url, @base_url))
    plug(Tesla.Middleware.Headers, [{"Content-Type", "application/json"}])
    plug(Tesla.Middleware.Logger, log_level: :info)

    plug(
      Tesla.Middleware.JSON,
      decode: &__MODULE__.custom_decode/1,
      encode: &__MODULE__.custom_encode/1
    )

    def custom_encode(x), do: ExGram.Encoder.encode(x)
    def custom_decode(x), do: ExGram.Encoder.decode(x, keys: :atoms)

    @impl ExGram.Adapter
    def request(verb, path, body) do
      body = encode_body(body)

      verb |> do_request(path, body) |> handle_result()
    end

    defp new() do
      custom_middlewares() |> Tesla.client(http_adapter())
    end

    defp do_request(:get, path, body) do
      body = Enum.to_list(body)
      new() |> get(path, query: body, opts: opts())
    end

    defp do_request(:post, path, body) do
      new() |> post(path, body, opts: opts())
    end

    defp handle_result({:ok, %{body: %{ok: true, result: body}, status: status}})
         when status in 200..299 do
      {:ok, body}
    end

    defp handle_result({:ok, %{body: body}}) do
      {:error, %ExGram.Error{code: :response_status_not_match, message: encode(body)}}
    end

    defp handle_result({:error, reason}) do
      {:error, %ExGram.Error{code: reason}}
    end

    defp encode_body(body) when is_map(body) do
      body
      |> Enum.map(fn {key, value} -> {key, encode(value)} end)
      |> Enum.into(%{})
    end

    defp encode_body({:multipart, parts}) do
      mp = Tesla.Multipart.new() |> Tesla.Multipart.add_content_type_param("charset=utf-8")
      Enum.reduce(parts, mp, &add_multipart_part/2)
    end

    defp add_multipart_part({:file, name, path}, mp) do
      Tesla.Multipart.add_file(mp, path, name: name)
    end

    defp add_multipart_part({:file_content, name, content, filename}, mp) do
      Tesla.Multipart.add_file_content(mp, content, filename, name: name)
    end

    defp add_multipart_part({name, value}, mp) do
      Tesla.Multipart.add_field(mp, name, value)
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

    defp http_adapter(), do: Application.get_env(:tesla, :adapter) || Tesla.Adapter.Hackney

    defp opts(), do: [adapter: adapter_opts()]
    defp adapter_opts(), do: [connect_timeout: 20_000, timeout: 60_000, recv_timeout: 60_000]

    defp format_middleware({m, f, a}) do
      case apply(m, f, a) do
        {_, _} = middleware -> {:ok, middleware}
        _ -> :error
      end
    end

    defp format_middleware({_, _} = mf), do: {:ok, mf}
    defp format_middleware(_), do: :error

    defp custom_middlewares() do
      middlewares = Application.get_env(:ex_gram, __MODULE__, [])[:middlewares] || []

      middlewares
      |> Enum.reduce([], fn elem, acc ->
        case format_middleware(elem) do
          {:ok, middleware} ->
            [middleware | acc]

          :error ->
            Logger.warn("Discarded, element is not a middleware: #{inspect(elem)}")
            acc
        end
      end)
      |> Enum.reverse()
    end
  end
end
