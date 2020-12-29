defmodule ExGram.Macros.Helpers do
  @moduledoc """
  Helpers for the ExGram.Macros module
  """

  def analyze_param({:{}, line, [{name, _line, nil}]}), do: {{name, line, nil}, [name, [:any]]}

  def analyze_param({:{}, line, [{name, _line, nil}, types, :optional]}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def analyze_param({name, _line, nil} = full), do: {full, [name, [:any]]}

  def analyze_param({{name, line, nil}, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, [:any], :optional]}

  def analyze_param({{name, line, nil}, types}), do: {{name, line, nil}, [name, types]}

  def analyze_param({{name, line, nil}, types, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def mandatory_type_specs(analyzed) do
    analyzed
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&(not is_par_optional(&1)))
    |> Enum.map(fn [n, ts] -> parameter_type_spec(n, types_list_to_spec(ts)) end)
  end

  def mandatory_value_type(analyzed) do
    analyzed
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&(not is_par_optional(&1)))
    |> Enum.map(fn [name, types] -> [nid(name), types] end)
  end

  def optional_type_specs(analyzed) do
    analyzed
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&is_par_optional/1)
    |> Enum.map(fn [n, ts, :optional] -> {n, types_list_to_spec(ts)} end)
    |> Kernel.++(common_opts())
  end

  def mandatory_parameters(analyzed) do
    mandatory =
      analyzed
      |> Enum.filter(fn {_name, desc} -> not is_par_optional(desc) end)

    names = Enum.map(mandatory, fn {name, _desc} -> name end)

    mand_atoms = Enum.map(names, &extract_param_name/1)
    mand_values = Enum.map(mand_atoms, &nid/1)

    body = Enum.zip(mand_atoms, mand_values)

    {names, body}
  end

  def optional_parameters(analyzed) do
    optionals =
      analyzed
      |> Enum.map(&elem(&1, 1))
      |> Enum.filter(&is_par_optional/1)

    optional_types = Enum.map(optionals, fn [name, types, :optional] -> {name, types} end)
    optional_names = Enum.map(optionals, fn [name, _, _] -> name end)

    {optional_names, optional_types}
  end

  def file_parameters(analyzed) do
    analyzed
    |> Enum.map(fn {_n, types} -> types end)
    |> Enum.filter(fn [_n, t | _] -> Enum.any?(t, &(&1 == :file or &1 == :file_content)) end)
    |> Enum.map(fn
      [n, _t] -> {nid(n), Atom.to_string(n)}
      [n, _t, :optional] -> n
    end)
  end

  def type_to_spec(:string),
    do: {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}

  def type_to_spec(:enum),
    do: {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :t]}, [], []}

  def type_to_spec(:file) do
    orT(
      {:file, type_to_spec(:string)},
      type_to_spec(:file_content)
    )
  end

  def type_to_spec(:file_content) do
    {:{}, [], [:file_content, type_to_spec(:file_data), type_to_spec(:string)]}
  end

  def type_to_spec(:file_data) do
    orT(type_to_spec(:iodata), type_to_spec(:enum))
  end

  def type_to_spec({:array, t}), do: {:list, [], [type_to_spec(t)]}
  def type_to_spec(:integer), do: {:integer, [], []}
  def type_to_spec(:boolean), do: {:boolean, [], []}
  def type_to_spec(true), do: true

  def type_to_spec({:__aliases__, _a, [:ExGram, :Model | _]} = f) do
    quote do
      unquote(f).t
    end
  end

  def type_to_spec({:__aliases__, _a, _} = f) do
    quote do
      ExGram.Model.unquote(f).t
    end
  end

  def type_to_spec(t) when is_atom(t), do: {t, [], Elixir}
  def type_to_spec(l) when is_list(l), do: types_list_to_spec(l)

  defp types_list_to_spec([e1]) do
    type_to_spec(e1)
  end

  defp types_list_to_spec([e1 | rest]) do
    orT(type_to_spec(e1), types_list_to_spec(rest))
  end

  defp types_list_to_spec([]) do
    type_to_spec(:any)
  end

  @common_opts [
    adapter: :atom,
    bot: :atom,
    token: :string,
    debug: :boolean,
    check_params: :boolean
  ]
  defp common_opts do
    @common_opts |> Enum.map(fn {k, v} -> {k, type_to_spec(v)} end)
  end

  defp parameter_type_spec(n, t) when is_atom(n), do: {:"::", [], [type_to_spec(n), t]}
  defp parameter_type_spec(n, t), do: {:"::", [], [n, t]}

  defp nid(x), do: {x, [], nil}

  defp is_par_optional([_n, _t, :optional]), do: true
  defp is_par_optional(_), do: false

  defp extract_param_name({name, _line, nil}), do: name
  defp extract_param_name({:\\, _line, [{name, _line2, nil}, nil]}), do: name

  # MODEL helpers

  def params_to_decode_as(params) do
    params
    |> Stream.map(fn
      {k, v} -> {k, v}
      {:{}, _, [k, v, :optional]} -> {k, v}
    end)
    |> Stream.map(fn {k, v} ->
      {k, param_to_decode_as(v)}
    end)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end

  defp param_to_decode_as({:array, type}) do
    case param_to_decode_as(type) do
      nil ->
        nil

      t ->
        quote do
          [unquote(t)]
        end
    end
  end

  defp param_to_decode_as({:__aliases__, _, _} = st) do
    quote do
      ExGram.Model.unquote(st)
    end
  end

  defp param_to_decode_as(_other), do: nil

  def struct_type_specs([], acc), do: acc

  def struct_type_specs([{id, t} | xs], acc) do
    act = acc ++ [{id, type_to_spec(t)}]

    xs
    |> struct_type_specs(act)
  end

  def struct_type_specs([{:{}, _line, [id, t, :optional]} | xs], acc) do
    act = acc ++ [{id, {:|, [], [type_to_spec(t), nil]}}]

    xs
    |> struct_type_specs(act)
  end

  def struct_type_specs(_x, acc) do
    # Logger.error "WTF struct?"
    # Logger.error inspect(x)
    struct_type_specs(acc)
  end

  def struct_type_specs(initial), do: struct_type_specs(initial, [])

  # credo:disable-for-next-line
  defp orT({:|, _, [x, y]}, z), do: orT(x, orT(y, z))
  defp orT(x, y), do: {:|, [], [x, y]}
end
