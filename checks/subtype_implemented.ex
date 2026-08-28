defmodule ExGram.Credo.SubtypeImplemented do
  @moduledoc false

  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    category: :warning,
    param_defaults: [ignore: []],
    explanations: [
      check: """
      Modules defining `subtypes/0` (union-type parent models) must have a
      corresponding `ExGram.Model.Subtype` protocol implementation, and that
      implementation must resolve every subtype the parent lists, otherwise
      `ExGram.Cast` cannot resolve the correct concrete type when deserializing
      Telegram API responses.

      The parent models are generated from the Telegram docs by `extractor.py`
      while the protocol implementations are written by hand, so a Bot API update
      can add a subtype that no `subtype/2` clause resolves. Casting a response
      containing one then fails at runtime with a `FunctionClauseError`.
      """,
      params: [
        ignore: "Subtype modules that intentionally have no `subtype/2` clause."
      ]
    ]

  alias Credo.Check.Params
  alias Credo.Execution.ExecutionIssues

  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    model_source = find_model_source(source_files)

    if model_source do
      implementations = find_implementations(source_files)
      ignored = ignored_subtypes(params)

      issues =
        model_source
        |> find_subtype_parents()
        |> Enum.flat_map(fn parent ->
          case Map.fetch(implementations, parent.module) do
            :error -> [missing_impl_issue(parent, model_source, params)]
            {:ok, resolved} -> unresolved_issues(parent, resolved, ignored, model_source, params)
          end
        end)

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

  # AST-walks lib/ex_gram.ex to find all defmodule blocks containing `def subtypes`.
  # Returns a list of %{module:, line:, subtypes:}, all fully qualified.
  defp find_subtype_parents(source_file) do
    Credo.Code.prewalk(source_file, &find_parents(&1, &2))
  end

  defp find_parents({:defmodule, meta, [{:__aliases__, _, parts}, [do: body]]} = ast, acc) do
    case subtypes_list(body) do
      nil ->
        {ast, acc}

      subtypes ->
        parent = %{
          module: model_module(parts),
          line: meta[:line],
          subtypes: Enum.map(subtypes, &model_module/1)
        }

        {ast, [parent | acc]}
    end
  end

  defp find_parents(ast, acc), do: {ast, acc}

  # The subtype models are nested inside ExGram.Model, so they are listed unqualified
  defp model_module(parts), do: Module.concat([ExGram, Model | parts])

  # Returns the alias parts listed by `def subtypes`, or nil when the body has no such def
  defp subtypes_list({:__block__, _, statements}), do: Enum.find_value(statements, &subtypes_from/1)
  defp subtypes_list(single), do: subtypes_from(single)

  defp subtypes_from({:def, _, [{:subtypes, _, _}, [do: list]]}) when is_list(list) do
    Enum.flat_map(list, fn
      {:__aliases__, _, parts} -> [parts]
      _ -> []
    end)
  end

  defp subtypes_from(_), do: nil

  # AST-scans all source files for `defimpl ExGram.Model.Subtype, for: X`.
  # Returns a map of the implemented module to the set of modules its clauses resolve to.
  defp find_implementations(source_files) do
    source_files
    |> Enum.flat_map(fn sf -> Credo.Code.prewalk(sf, &find_impls(&1, &2)) end)
    |> Map.new()
  end

  # Matches: defimpl ExGram.Model.Subtype, for: ExGram.Model.SomeModule
  defp find_impls(
         {:defimpl, _meta,
          [{:__aliases__, _, [:ExGram, :Model, :Subtype]}, [for: {:__aliases__, _, for_parts}], [do: body]]} = ast,
         acc
       ) do
    {ast, [{Module.concat(for_parts), resolved_modules(body)} | acc]}
  end

  defp find_impls(ast, acc), do: {ast, acc}

  # Collects the module every `def subtype(_, selector), do: Module` clause returns
  defp resolved_modules(body) do
    {_ast, modules} =
      Macro.prewalk(body, [], fn
        {:def, _, [{:subtype, _, _}, [do: {:__aliases__, _, parts}]]} = node, acc ->
          {node, [Module.concat(parts) | acc]}

        node, acc ->
          {node, acc}
      end)

    MapSet.new(modules)
  end

  defp ignored_subtypes(params) do
    params
    |> Params.get(:ignore, __MODULE__)
    |> List.wrap()
    |> MapSet.new()
  end

  defp missing_impl_issue(parent, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    format_issue(issue_meta,
      message: "#{inspect(parent.module)} defines subtypes/0 but has no ExGram.Model.Subtype protocol implementation.",
      trigger: inspect(parent.module),
      line_no: parent.line
    )
  end

  defp unresolved_issues(parent, resolved, ignored, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    parent.subtypes
    |> Enum.reject(&(MapSet.member?(resolved, &1) or MapSet.member?(ignored, &1)))
    |> Enum.map(fn subtype ->
      format_issue(issue_meta,
        message:
          "#{inspect(subtype)} is listed in #{inspect(parent.module)}.subtypes/0 " <>
            "but no subtype/2 clause resolves it.",
        trigger: inspect(subtype),
        line_no: parent.line
      )
    end)
  end
end
