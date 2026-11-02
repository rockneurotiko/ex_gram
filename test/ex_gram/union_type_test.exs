defmodule ExGram.UnionTypeTest do
  use ExUnit.Case, async: true

  alias ExGram.Model

  defp type_t(union) do
    {:ok, types} = Code.Typespec.fetch_types(union)
    {_, {:t, form, []}} = Enum.find(types, &match?({:type, {:t, _, _}}, &1))
    form
  end

  # Alternatives of the top-level union of the type `t`.
  defp alternatives({:type, _, :union, alts}), do: alts
  defp alternatives(form), do: [form]

  # Modules covered by the `t` type of a union, either as a remote type (`Sub.t()`)
  # or as a struct name inside a shared map type (`%{__struct__: A | B, ...}`).
  defp covered_modules(union) do
    union
    |> type_t()
    |> alternatives()
    |> Enum.flat_map(&alternative_modules/1)
    |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "Elixir.ExGram.Model."))
    |> Enum.sort()
  end

  defp alternative_modules({:remote_type, _, [{:atom, _, mod}, {:atom, _, :t}, []]}), do: [mod]

  defp alternative_modules({:type, _, :map, assocs}) do
    assocs
    |> Enum.filter(&match?({:type, _, :map_field_exact, [{:atom, _, :__struct__}, _]}, &1))
    |> Enum.flat_map(fn {:type, _, _, [_, names]} -> atoms(names) end)
  end

  defp alternative_modules(_other), do: []

  defp atoms({:atom, _, name}), do: [name]
  defp atoms({:type, _, :union, names}), do: Enum.flat_map(names, &atoms/1)

  defp unions do
    {:ok, modules} = :application.get_key(:ex_gram, :modules)
    Enum.filter(modules, &(Code.ensure_loaded?(&1) and function_exported?(&1, :subtypes, 0)))
  end

  test "every union covers exactly its subtypes" do
    assert unions() != []

    for union <- unions() do
      assert covered_modules(union) == Enum.sort(union.subtypes()), inspect(union)
    end
  end

  test "subtypes with the same fields share one map type" do
    shared =
      Model.RichText
      |> type_t()
      |> alternatives()
      |> Enum.map(&alternative_modules/1)
      |> Enum.filter(&(Model.RichTextBold in &1))

    assert [[_, _, _ | _] = group] = shared
    assert Model.RichTextItalic in group
  end

  test "subtypes with different fields stay apart" do
    groups = Model.RichText |> type_t() |> alternatives() |> Enum.map(&alternative_modules/1)

    assert [Model.RichTextDateTime] in groups
  end
end
