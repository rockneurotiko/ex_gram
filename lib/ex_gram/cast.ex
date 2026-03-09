defmodule ExGram.Cast do
  @moduledoc """
  Helper module to convert plain values returned from Telegram to ExGram models.

  This module handles the conversion of plain maps (JSON responses from the Telegram
  Bot API) into strongly-typed ExGram model structs. It recursively processes nested
  structures, arrays, and polymorphic types (subtypes).

  See `ExGram.Model.Subtype` for how polymorphic types are handled.
  """

  alias ExGram.Model.Subtype

  @doc """
  Converts the given plain value to ExGram models.

    iex> ExGram.Cast.cast(%{message_id: 3, chat: %{id: 5}}, ExGram.Model.Message)
    {:ok, %ExGram.Model.Message{message_id: 3, chat: %ExGram.Model.Chat{id: 5}}}

    iex> ExGram.Cast.cast(true, ExGram.Model.Message)
    {:error, %ExGram.Error{message: "Expected a map for type ExGram.Model.Message, got: true"}}
  """
  @type type_def :: atom() | {:array, type_def()} | [type_def()] | nil

  @spec cast(any(), type_def()) :: {:ok, any()} | {:error, ExGram.Error.t()}
  def cast(elem, type) do
    process_type(elem, type)
  end

  @doc """
  Converts the given plain value to ExGram models.

  Raises an error if the conversion fails. See `cast/2` for more details.
  """
  @spec cast!(any(), type_def()) :: any()
  def cast!(elem, type) do
    case cast(elem, type) do
      {:ok, casted} ->
        casted

      {:error, reason} ->
        raise ExGram.Error, message: reason.message
    end
  end

  defp process_type(nil, _), do: {:ok, nil}
  defp process_type(elem, nil), do: {:ok, elem}

  defp process_type(list, [t]) when is_list(list), do: process_type(list, {:array, t})

  defp process_type([], {:array, _}), do: {:ok, []}

  defp process_type(list, {:array, t}) when is_list(list) do
    list
    |> Enum.reduce_while({:ok, []}, fn elem, {:ok, acc} ->
      case process_type(elem, t) do
        {:ok, processed} -> {:cont, {:ok, [processed | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, processed_list} -> {:ok, Enum.reverse(processed_list)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_type(elem, :integer), do: {:ok, elem}
  defp process_type(elem, :string), do: {:ok, elem}
  defp process_type(true, true), do: {:ok, true}

  defp process_type(elem, t) when is_atom(t) do
    if subtype?(t) do
      apply_subtype(t, elem)
    else
      process_struct(t, elem)
    end
  end

  defp process_type(elem, [t]), do: process_type(elem, t)

  defp process_type(elem, types) when is_list(types) do
    Enum.reduce_while(
      types,
      {:error,
       %ExGram.Error{message: "Value #{inspect(elem)} does not match any of the expected types: #{inspect(types)}"}},
      fn t, error ->
        case process_type(elem, t) do
          {:ok, processed} -> {:halt, {:ok, processed}}
          {:error, _} -> {:cont, error}
        end
      end
    )
  end

  defp process_type(elem, _t), do: {:ok, elem}

  defp process_struct(t, %t{} = elem), do: elem

  defp process_struct(t, elem) when is_map(elem) do
    with {:ok, decode_as} <- struct_decode_as(t),
         {:ok, decoded_elem} <- decode_struct_elements(elem, decode_as) do
      {:ok, struct(t, decoded_elem)}
    end
  end

  defp process_struct(t, elem) do
    {:error, %ExGram.Error{message: "Expected a map for type #{inspect(t)}, got: #{inspect(elem)}"}}
  end

  defp decode_struct_elements(elem, decode_as) do
    Enum.reduce_while(decode_as, {:ok, %{}}, fn {k, v}, {:ok, acc} ->
      case cast(elem[k], v) do
        {:ok, processed} -> {:cont, {:ok, Map.put(acc, k, processed)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp struct_decode_as(t) do
    # We can't check if the struct implements decode_as/0 because the models are sometimes not loaded
    {:ok, Map.from_struct(t.decode_as())}
  rescue
    _ ->
      {:error, %ExGram.Error{message: "Module #{inspect(t)} does not implement decode_as/0"}}
  end

  defp subtype?(t) do
    Subtype.impl_for(struct(t, %{}))
  rescue
    _ -> false
  end

  defp apply_subtype(t, params) when is_map(params) do
    base = struct(t, %{})
    selector = Subtype.selector_value(base, params)
    subtype = Subtype.subtype(base, selector)

    process_struct(subtype, params)
  rescue
    e ->
      {:error, %ExGram.Error{message: "Failed to resolve subtype for #{inspect(t)}: #{Exception.message(e)}"}}
  end

  defp apply_subtype(t, params) do
    {:error, %ExGram.Error{message: "Expected a map for type #{inspect(t)}, got: #{inspect(params)}"}}
  end
end
