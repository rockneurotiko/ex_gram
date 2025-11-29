defmodule ExGram.Adapter do
  @moduledoc """
  Behaviour for HTTP adapters
  """

  @type verb :: :post | :get
  @type path :: String.t()
  @type body :: map() | list()
  @type result_request :: {:ok, map} | {:error, ExGram.Error.t()}

  @callback request(verb, path, body) :: result_request

  def encode(%{__struct__: _} = x) do
    x
    |> Map.from_struct()
    |> ExGram.Adapter.filter_map()
    |> ExGram.Encoder.encode!()
  end

  def encode(x) when is_map(x) or is_list(x), do: ExGram.Encoder.encode!(x)
  def encode(x), do: x

  def filter_map(%{__struct__: _} = m) do
    m |> Map.from_struct() |> filter_map()
  end

  def filter_map(m) when is_map(m) do
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

  def filter_map(m) when is_list(m), do: Enum.map(m, &filter_map/1)
  def filter_map(m), do: m
end
