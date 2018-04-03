defmodule Telex.Adapter.Http do
  @behaviour Telex.Adapter

  @impl Telex.Adapter
  def request(verb, path, body) do
    where = where_body(verb)

    Telex.new_conn()
    |> Telex.conn_put_path(path)
    |> add_body(where, body)
    |> do_request(verb)
    |> post_request()
  end

  defp post_request({:ok, %Maxwell.Conn{status: status} = conn}) when status in 200..299 do
    {:ok, Maxwell.Conn.get_resp_body(conn, :result)}
  end

  defp post_request({:ok, conn}) do
    body = Maxwell.Conn.get_resp_body(conn) |> encode()
    {:error, %Telex.Error{code: :response_status_not_match, message: body}}
  end

  defp post_request({:error, reason, conn}) do
    error = Maxwell.Error.exception({__MODULE__, reason, conn})
    {:error, %Telex.Error{code: error.status, message: error.message}}
  end

  defp post_request({:error, reason}) do
    {:error, %Telex.Error{code: reason}}
  end

  defp do_request(conn, verb) do
    apply(Telex, verb, [conn])
  end

  defp add_body(conn, where, body) do
    apply(Maxwell.Conn, where, [conn, encode_body(body)])
  end

  defp where_body(:post), do: :put_req_body
  defp where_body(_), do: :put_query_string

  defp encode_body(body) do
    if is_map(body) do
      body
      |> Enum.map(fn {key, value} -> {key, encode(value)} end)
      |> Enum.into(%{})
    else
      body
    end
  end

  defp encode(%{__struct__: _} = x) do
    x
    |> Map.from_struct()
    |> filter_map
    |> Poison.encode!()
  end

  defp encode(x) when is_map(x) or is_list(x), do: Poison.encode!(x)
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
