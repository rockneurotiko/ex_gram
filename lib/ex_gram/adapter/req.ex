if Code.ensure_loaded?(Req) do
  defmodule ExGram.Adapter.Req do
    @moduledoc """
    HTTP Adapter that uses Req
    """
    @behaviour ExGram.Adapter

    require Logger

    @base_url "https://api.telegram.org"

    @impl ExGram.Adapter
    def request(verb, path, body) do
      Req.Request.new(method: verb, url: path)
      |> Req.Request.register_options([:base_url, :json])
      |> Req.Request.put_new_option(:base_url, ExGram.Config.get(:ex_gram, :base_url, @base_url))
      |> put_body_option(body)
      |> Req.Steps.put_base_url()
      |> Req.Request.append_request_steps(custom_encode: &custom_encode/1)
      |> Req.Request.append_response_steps(custom_decode: &custom_decode/1)
      |> Req.Request.run_request()
      |> handle_result()
    end

    ## TO_DO: test this i dont know if this ExGram parts, satisfy the
    ## the format Req wants for multipart, maybe require some sort
    ## of transformation.
    defp put_body_option(req, {:multipart, parts}) do
      req |> Req.Request.put_new_option(:form_multipart, parts)
    end

    defp put_body_option(req, body) when is_map(body) do
      req |> Req.Request.put_new_option(:json, body)
    end

    defp custom_encode(request) do
      cond do
        data = request.options[:form_multipart] ->
          ## TO_DO: This might fail if `parts` value from ExGram does not satisfy
          # the same format as Req.
          multipart = Req.Utils.encode_form_multipart(data)

          %{request | body: multipart.body}
          |> Req.Request.put_new_header("content-type", multipart.content_type)
          |> then(&maybe_put_content_length(&1, multipart.size))

        data = request.options[:json] ->
          %{request | body: Map.new(data, fn {key, value} -> {key, encode(value)} end)}
          |> Req.Request.put_new_header("Content-Type", "application/json")
          |> Req.Request.put_new_header("Accept", "application/json")

        true ->
          request
      end
    end

    defp maybe_put_content_length(req, nil), do: req

    defp maybe_put_content_length(req, size) do
      Req.Request.put_new_header(req, "content-length", Integer.to_string(size))
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
      m |> Map.from_struct() |> filter_map()
    end

    defp filter_map(m) when is_map(m) do
      m
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Map.new(fn {key, value} ->
        cond do
          is_list(value) -> {key, Enum.map(value, &filter_map/1)}
          is_map(value) -> {key, filter_map(value)}
          true -> {key, value}
        end
      end)
    end

    defp filter_map(m) when is_list(m), do: Enum.map(m, &filter_map/1)
    defp filter_map(m), do: m

    defp custom_decode({request, response}) do
      case ExGram.Encoder.decode(response.body, keys: :atoms) do
        {:ok, decoded} ->
          {request, put_in(response.body, decoded)}

        {:error, e} ->
          {request, e}
      end
    end

    defp handle_result({_req, %Req.Response{status: status} = response})
         when status in 200..299 do
      {:ok, response}
    end

    defp handle_result({_req, %Req.Response{} = response}) do
      {:error, %ExGram.Error{code: response.status}}
    end

    defp handle_result({_req, exception}) do
      {:error, exception}
    end
  end
end
