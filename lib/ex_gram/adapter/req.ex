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
      |> Req.Request.put_new_option(:json, body)
      |> Req.Steps.put_base_url()
      |> Req.Request.append_request_steps(custom_encode: &custom_encode/1)
      |> Req.Request.append_response_steps(custom_decode: &custom_decode/1 )
      |> Req.Request.run_request()
      |> handle_result()
    end

    defp custom_encode(request) do
      cond do
        data = request.options[:json] ->
          %{request | body: ExGram.Encoder.encode(data)}
          |> Req.Request.put_new_header("Content-Type", "application/json")
          |> Req.Request.put_new_header("Accept", "application/json")

        true ->
          request
      end
    end

    defp custom_decode({request, response}) do
      case ExGram.Encoder.decode(response.body, keys: :atoms) do
        {:ok, decoded} ->
          {request, put_in(response.body, decoded)}

        {:error, e} ->
          {request, e}
      end
    end

    defp handle_result({_req, %Req.Response{status: status} = response}) when status in 200..299 do
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
