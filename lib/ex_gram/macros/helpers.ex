defmodule ExGram.Macros.Helpers do
  def process_result(list, [t]), do: Enum.map(list, &process_result(&1, t))

  def process_result(elem, :integer), do: elem
  def process_result(elem, :string), do: elem
  def process_result(elem, true), do: elem

  def process_result(elem, t) when is_atom(t) do
    struct(t, elem)
  end

  def process_result(elem, _t), do: elem

  def check_params(true, mandatory, optional, optional_types) do
    mandatory_checks = mandatory |> Stream.map(&normalize_param/1) |> check_mandatory_params()

    optional_checks =
      optional
      |> Stream.map(&normalize_param/1)
      |> Stream.map(fn [key, value] ->
        check_all_types([value, Keyword.get(optional_types, key)])
      end)
      |> Enum.all?()

    mandatory_checks && optional_checks
  end

  def check_params(false, _mandatory, _optional, _optional_types), do: true

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

  def to_size_string(true), do: "true"
  def to_size_string(false), do: "false"
  def to_size_string(x) when is_binary(x), do: x
  def to_size_string(x) when is_integer(x), do: Integer.to_string(x)
  # This is usefull to encode automatically
  def to_size_string(x) when is_map(x), do: encode(x)
  def to_size_string(_), do: raise("Not sizable!")

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

  def clean_body(%{__struct__: _} = m) do
    m |> Map.from_struct() |> clean_body()
  end

  def clean_body(map) when is_map(map) do
    for {k, v} <- map, not is_nil(v), into: %{}, do: {k, clean_body(v)}
  end

  def clean_body(m) when is_list(m), do: Enum.map(m, &clean_body/1)
  def clean_body(m), do: m

  defp orT({:|, _, [x, y]}, z), do: orT(x, orT(y, z))
  defp orT(x, y), do: {:|, [], [x, y]}

  defp check_mandatory_params(params) do
    params
    |> Stream.filter(fn
      [_x, _t, :optional] ->
        false

      # {_x, _t, :optional} -> false
      _ ->
        true
    end)
    |> Enum.map(&check_all_types/1)
    |> Enum.all?()
  end

  defp normalize_param(params) when is_tuple(params), do: Tuple.to_list(params)
  defp normalize_param(params), do: params

  defp check_all_types([x, types]), do: Enum.any?(types, &check_type(&1, x))
  defp check_all_types([x, types, :optional]), do: x == nil or check_all_types({x, types})
  # defp check_all_types({x, types}), do: check_all_types([x, types])
  # defp check_all_types({x, types, :optional}), do: check_all_types([x, types, :optional])

  defp check_type(:integer, x), do: is_integer(x)
  defp check_type(:string, x), do: is_bitstring(x)
  defp check_type(:boolean, x), do: is_boolean(x)
  defp check_type(:float, x), do: is_float(x)
  # TODO?
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

  defp last_part_name(name) when is_binary(name), do: name |> String.split(".") |> List.last()
  defp last_part_name(name), do: name

  defp encode(%{__struct__: _} = x) do
    x
    |> Map.from_struct()
    |> clean_body()
    |> ExGram.Encoder.encode!()
  end

  defp encode(x) when is_map(x) or is_list(x), do: ExGram.Encoder.encode!(x)
  defp encode(x), do: x
end
