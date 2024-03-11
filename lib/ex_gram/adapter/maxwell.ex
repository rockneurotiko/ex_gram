if Code.ensure_loaded?(Maxwell) do
  defmodule ExGram.Adapter.Maxwell do
    @moduledoc """
    [DEPRECATED] HTTP Adapter that uses Maxwell
    """

    @behaviour ExGram.Adapter

    @impl ExGram.Adapter
    def request(_verb, _path, _body) do
      raise "Maxwell is deprecated if you want to use it, use your own adapter"
    end
  end
end
