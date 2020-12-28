defmodule ExGram.Macros.Helpers do
  def nameAssignT(n, t) when is_atom(n), do: {:"::", [], [type_to_spec(n), t]}
  def nameAssignT(n, t), do: {:"::", [], [n, t]}

  def nid(x), do: {x, [], nil}

  def type_to_macrot([n, t]), do: [nid(n), t]
  def type_to_macrot([n, t, o]), do: [nid(n), t, o]

  def partition_optional_parameter({_, [_n, _t, :optional]}), do: true
  def partition_optional_parameter(_), do: false

  def is_par_optional([_n, _t, :optional]), do: true
  def is_par_optional(_), do: false

  def process_result(list, [t]), do: Enum.map(list, &process_result(&1, t))

  def process_result(elem, :integer), do: elem
  def process_result(elem, :string), do: elem
  def process_result(elem, true), do: elem

  def process_result(elem, t) when is_atom(t) do
    struct(t, elem)
  end

  def process_result(elem, _t), do: elem

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

  def type_to_spec({:__aliases__, _a, _t} = f) do
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
