if Code.ensure_loaded?(Req) do
  defmodule ExGram.Adapter.Req do
    @moduledoc """
    HTTP Adapter that uses Req
    """
    @behaviour ExGram.Adapter

    @base_url "https://api.telegram.org"

    @impl ExGram.Adapter
    def request(verb, path, body) do
      [method: coerce_verb(verb), url: path]
      |> Req.Request.new()
      |> Req.Request.register_options([:base_url, :json, :form_multipart])
      |> Req.Request.put_new_option(:base_url, ExGram.Config.get(:ex_gram, :base_url, @base_url))
      |> put_body_option(body)
      |> Req.Steps.put_base_url()
      |> Req.Request.append_request_steps(custom_encode: &custom_encode/1)
      |> Req.Request.append_response_steps(custom_decode: &custom_decode/1)
      |> Req.Request.run_request()
      |> handle_result()
    end

    defp coerce_verb(:get), do: :post
    defp coerce_verb(verb), do: verb

    defp req_parts({:file, name, path}, parts) do
      parts ++ [{name, File.stream!(path, 2048)}]
    end

    defp req_parts({:file_content, name, content, filename}, parts) do
      parts ++ [{name, {content, filename: filename}}]
    end

    defp req_parts({name, value}, parts) do
      parts ++ [{name, value}]
    end

    defp put_body_option(req, {:multipart, parts}) do
      parts = Enum.reduce(parts, [], fn part, acc -> req_parts(part, acc) end)
      Req.Request.put_new_option(req, :form_multipart, parts)
    end

    defp put_body_option(req, body) when is_map(body) do
      Req.Request.put_new_option(req, :json, body)
    end

    defp custom_encode(request) do
      cond do
        data = request.options[:form_multipart] ->
          multipart = Req.Utils.encode_form_multipart(data)

          %{request | body: multipart.body}
          |> Req.Request.put_new_header("content-type", multipart.content_type)
          |> maybe_put_content_length(multipart.size)

        data = request.options[:json] ->
          %{request | body: ExGram.Adapter.encode(data)}
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

    defp custom_decode({request, response}) do
      case ExGram.Encoder.decode(response.body, keys: :atoms) do
        {:ok, decoded} ->
          {request, put_in(response.body, decoded)}

        {:error, e} ->
          {request, e}
      end
    end

    defp handle_result({_req, %Req.Response{status: status, body: %{ok: true, result: body}} = _response})
         when status in 200..299 do
      {:ok, body}
    end

    defp handle_result({_req, %Req.Response{body: body} = _response}) do
      {:error, %ExGram.Error{code: :response_status_not_match, message: ExGram.Adapter.encode(body)}}
    end

    defp handle_result({_req, exception}) do
      {:error, %ExGram.Error{code: exception}}
    end
  end
end
