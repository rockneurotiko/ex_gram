defmodule ExGram.Cast do
  @moduledoc """
  Helper module to convert plain values returned from Telegram to ExGram models.
  """

  @doc """
  Converts the given plain value to ExGram models.

    iex> ExGram.Cast.cast(%{message_id: 3, chat: %{id: 5}}, ExGram.Model.Message)
    %ExGram.Model.Message{message_id: 3, chat: %ExGram.Model.Chat{id: 5}}
  """
  def cast(elem, type) do
    process_type(elem, type)
  end

  defp process_type(nil, _), do: nil
  defp process_type(elem, nil), do: elem

  defp process_type(list, {:array, t}), do: Enum.map(list, &process_type(&1, t))
  defp process_type(list, [t]), do: Enum.map(list, &process_type(&1, t))

  defp process_type(elem, :integer), do: elem
  defp process_type(elem, :string), do: elem
  defp process_type(elem, true), do: elem

  defp process_type(elem, t) when is_atom(t) do
    if is_subtype?(t) do
      apply_subtype(t, elem)
    else
      process_struct(t, elem)
    end
  end

  defp process_type(elem, _t), do: elem

  defp process_struct(t, elem) do
    decoded_elem =
      t.decode_as()
      |> Map.from_struct()
      |> Map.new(fn {k, v} ->
        {k, process_type(elem[k], v)}
      end)

    struct(t, decoded_elem)
  end

  defp is_subtype?(t) do
    ExGram.Model.Subtype.impl_for(struct(t, %{}))
  end

  defp apply_subtype(t, params) do
    base = struct(t, %{})
    selector = ExGram.Model.Subtype.selector_value(base, params)
    subtype = ExGram.Model.Subtype.subtype(base, selector)

    process_struct(subtype, params)
  end
end
