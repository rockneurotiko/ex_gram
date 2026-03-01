defmodule ExGram.Credo.SubtypeImplemented do
  @moduledoc false

  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Modules defining `subtypes/0` (union-type parent models) must have
      a corresponding `ExGram.Model.Subtype` protocol implementation,
      otherwise `ExGram.Cast` cannot resolve the correct concrete type
      when deserializing Telegram API responses.
      """
    ]

  alias Credo.Execution.ExecutionIssues

  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    model_source = find_model_source(source_files)

    if model_source do
      parents = find_subtype_parents(model_source)
      implemented = find_implemented_subtypes(source_files)

      issues =
        parents
        |> Enum.reject(fn {module, _line} -> MapSet.member?(implemented, module) end)
        |> Enum.map(&build_issue(&1, model_source, params))

      ExecutionIssues.append(exec, issues)
    end

    :ok
  end

  # Finds the source file containing ExGram.Model definitions
  defp find_model_source(source_files) do
    Enum.find(source_files, fn sf ->
      String.ends_with?(sf.filename, "lib/ex_gram.ex")
    end)
  end

  # AST-walks lib/ex_gram.ex to find all defmodule blocks containing `def subtypes`
  # Returns list of {fully_qualified_module_atom, line_number}
  defp find_subtype_parents(source_file) do
    Credo.Code.prewalk(source_file, &find_parents(&1, &2))
  end

  defp find_parents({:defmodule, meta, [{:__aliases__, _, parts}, [do: body]]} = ast, acc) do
    if defines_subtypes?(body) do
      full_name = Module.concat([ExGram, Model | parts])
      {ast, [{full_name, meta[:line]} | acc]}
    else
      {ast, acc}
    end
  end

  defp find_parents(ast, acc), do: {ast, acc}

  defp defines_subtypes?({:__block__, _, statements}) do
    Enum.any?(statements, &subtypes_def?/1)
  end

  defp defines_subtypes?(single), do: subtypes_def?(single)

  defp subtypes_def?({:def, _, [{:subtypes, _, _} | _]}), do: true
  defp subtypes_def?(_), do: false

  # AST-scans all source files for `defimpl ExGram.Model.Subtype, for: X`
  # Returns a MapSet of fully qualified module atoms that have implementations
  defp find_implemented_subtypes(source_files) do
    source_files
    |> Enum.flat_map(fn sf -> Credo.Code.prewalk(sf, &find_impls(&1, &2)) end)
    |> MapSet.new()
  end

  # Matches: defimpl ExGram.Model.Subtype, for: ExGram.Model.SomeModule
  defp find_impls(
         {:defimpl, _meta, [{:__aliases__, _, [:ExGram, :Model, :Subtype]}, [for: {:__aliases__, _, for_parts}] | _]} =
           ast,
         acc
       ) do
    {ast, [Module.concat(for_parts) | acc]}
  end

  defp find_impls(ast, acc), do: {ast, acc}

  defp build_issue({module, line}, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    format_issue(issue_meta,
      message: "#{inspect(module)} defines subtypes/0 but has no ExGram.Model.Subtype protocol implementation.",
      trigger: inspect(module),
      line_no: line
    )
  end
end
