defmodule ExGram.Macros.Checker do
  @moduledoc """
  Type checker for the method executer.
  """

  @type valid_type :: :integer | :string | :boolean | :float | :file | {:array, valid_type} | atom
  @type param_type :: maybe_improper_list(any, [valid_type])
  @type params_types :: [param_type]

  @type error_type_element :: {any, [valid_type]}

  @spec check_types(params_types) :: :ok | {:error, [{error_type_element, integer}]}
  def check_types(params) do
    errors =
      params
      |> Enum.map(&check_any_type/1)
      |> Enum.with_index()
      |> Enum.filter(fn
        {:ok, _} ->
          false

        _ ->
          true
      end)

    case errors do
      [] ->
        :ok

      _ ->
        {:error, errors}
    end
  end

  defp check_any_type([value, types]) do
    case Enum.any?(types, &check_type(&1, value)) do
      true -> :ok
      _ -> {value, types}
    end
  end

  defp check_type(types, x) when is_list(types), do: Enum.any?(types, &check_type(&1, x))

  defp check_type(:integer, x), do: is_integer(x)
  defp check_type(:string, x), do: is_bitstring(x)
  defp check_type(:boolean, x), do: is_boolean(x)
  defp check_type(:float, x), do: is_float(x)

  defp check_type(:file, {:file, _p}), do: true
  defp check_type(:file, {:file_content, _c, _fn}), do: true
  defp check_type(:file, _o), do: false

  defp check_type({:array, _}, []), do: true

  defp check_type({:array, t}, x) when is_list(x) do
    Enum.all?(x, &check_type(t, &1))
  end

  defp check_type({:array, _t}, _), do: false

  defp check_type(:any, _x), do: true

  defp check_type(t1, %{__struct__: t1}), do: true

  defp check_type(t1, %{__struct__: t2} = struct) do
    check_same_struct(t1, t2) || check_subtypes(t1, struct)
  end

  # defp check_type(t1, %{__struct__: t2}), do: t1 == t2
  defp check_type(%{}, x), do: is_map(x)

  defp check_same_struct(t1, t2) do
    t2s = Atom.to_string(t2)

    t2a =
      if name_is_model?(t2s) do
        name = last_part_name(t2s)
        String.to_atom("Elixir.#{name}")
      else
        t2
      end

    t1 == t2a
  end

  defp check_subtypes(t1, struct) do
    subtypes = extract_subtypes(t1)
    Enum.any?(subtypes, &check_type(&1, struct))
  end

  defp extract_subtypes(mod) when is_atom(mod), do: extract_subtypes(Atom.to_string(mod))

  defp extract_subtypes(mods) when is_binary(mods) do
    # mods = Atom.to_string(mod)

    mod =
      if name_is_model?(mods) do
        String.to_atom(mods)
      else
        name = last_part_name(mods)
        String.to_atom("Elixir.ExGram.Model.#{name}")
      end

    try do
      mod.subtypes()
    rescue
      _ -> []
    catch
      _ -> []
    end
  end

  defp extract_subtypes(_), do: []

  defp name_is_model?("Elixir.ExGram.Model." <> _), do: true
  defp name_is_model?(_), do: false

  defp last_part_name(name), do: name |> String.split(".") |> List.last()
end
