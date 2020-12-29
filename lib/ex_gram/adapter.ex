defmodule ExGram.Adapter do
  @moduledoc """
  Behaviour for HTTP adapters
  """

  @type verb :: :post | :get
  @type path :: String.t()
  @type body :: map() | list()
  @type result_request :: {:ok, map} | {:error, ExGram.Error.t()}

  @callback request(verb, path, body) :: result_request
end
