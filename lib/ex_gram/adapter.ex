defmodule ExGram.Adapter do
  @type verb :: :post | :get
  @type path :: String.t()
  @type body :: map() | list()
  @type result_request :: {:ok, map} | {:error, ExGram.Error.t()}

  @callback request(verb, path, body) :: result_request
end
