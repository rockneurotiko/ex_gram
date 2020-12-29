defmodule ExGram.Macros.Helpers do
  def mandatory_type_specs(analyzed) do
    analyzed
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&(not is_par_optional(&1)))
    |> Enum.map(fn [n, ts] -> nameAssignT(n, types_list_to_spec(ts)) end)
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

  defp nameAssignT(n, t) when is_atom(n), do: {:"::", [], [type_to_spec(n), t]}
  defp nameAssignT(n, t), do: {:"::", [], [n, t]}

  def nid(x), do: {x, [], nil}

  def partition_optional_parameter({_, [_n, _t, :optional]}), do: true
  def partition_optional_parameter(_), do: false

  defp is_par_optional([_n, _t, :optional]), do: true
  defp is_par_optional(_), do: false

  def transform_param({:{}, line, [{name, _line, nil}]}), do: {{name, line, nil}, [name, [:any]]}

  def transform_param({:{}, line, [{name, _line, nil}, types, :optional]}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def transform_param({name, _line, nil} = full), do: {full, [name, [:any]]}

  def transform_param({{name, line, nil}, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, [:any], :optional]}

  def transform_param({{name, line, nil}, types}), do: {{name, line, nil}, [name, types]}

  def transform_param({{name, line, nil}, types, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def extract_param_name({name, _line, nil}), do: name
  def extract_param_name({:\\, _line, [{name, _line2, nil}, nil]}), do: name

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

  def types_list_to_spec([e1]) do
    type_to_spec(e1)
  end

  def types_list_to_spec([e1 | rest]) do
    orT(type_to_spec(e1), types_list_to_spec(rest))
  end

  def types_list_to_spec([]) do
    type_to_spec(:any)
  end

  def params_to_decode(params) do
    params
    |> Stream.map(fn
      {k, v} -> {k, v}
      {:{}, _, [k, v, :optional]} -> {k, v}
    end)
    |> Stream.map(fn {k, v} ->
      {k, param_to_decode(v)}
    end)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end

  def param_to_decode({:array, type}) do
    case param_to_decode(type) do
      nil ->
        nil

      t ->
        quote do
          [unquote(t)]
        end
    end
  end

  def param_to_decode({:__aliases__, _, _} = st) do
    quote do
      ExGram.Model.unquote(st)
    end
  end

  def param_to_decode(_other), do: nil

  def struct_types([], acc), do: acc

  def struct_types([{id, t} | xs], acc) do
    act = acc ++ [{id, type_to_spec(t)}]

    xs
    |> struct_types(act)
  end

  def struct_types([{:{}, _line, [id, t, :optional]} | xs], acc) do
    act = acc ++ [{id, {:|, [], [type_to_spec(t), nil]}}]

    xs
    |> struct_types(act)
  end

  def struct_types(_x, acc) do
    # Logger.error "WTF struct?"
    # Logger.error inspect(x)
    struct_types(acc)
  end

  def struct_types(initial), do: struct_types(initial, [])

  defp orT({:|, _, [x, y]}, z), do: orT(x, orT(y, z))
  defp orT(x, y), do: {:|, [], [x, y]}
end
