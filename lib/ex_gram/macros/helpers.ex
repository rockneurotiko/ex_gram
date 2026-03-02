defmodule ExGram.Macros.Helpers do
  @moduledoc """
  Helpers for the ExGram.Macros module
  """

  @doc """
  Entry point for all the macros that has parameters (model + method).

  It analyzed the AST and return the list of params with the following format:
  - For mandatory parameters: `[name, types, description]`
  - For optional parameters: `[name, types, description, :optional]`

  All the other methods in this module that deal with parameters expect this format.
  """
  def analyze_params(params) do
    Enum.map(params, &analyze_param/1)
  end

  defp analyze_param({:{}, _line, [name, types, description]}), do: [param_name(name), types, description]

  defp analyze_param({:{}, _line, [name, types, description, :optional]}),
    do: [param_name(name), types, description, :optional]

  defp param_name({name, _nline, nil}), do: name
  defp param_name(name) when is_atom(name), do: name

  def mandatory_type_specs(analyzed) do
    analyzed
    |> Enum.filter(&(not par_optional?(&1)))
    |> Enum.map(fn [n, ts, _desc] -> parameter_type_spec(n, types_list_to_spec(ts)) end)
  end

  def mandatory_value_type(analyzed) do
    analyzed
    |> Enum.filter(&(not par_optional?(&1)))
    |> Enum.map(fn [name, types, _desc] -> [nid(name), types] end)
  end

  def optional_type_specs(analyzed) do
    analyzed
    |> Enum.filter(&par_optional?/1)
    |> Enum.map(fn [n, ts, _desc, :optional] -> {n, types_list_to_spec(ts)} end)
    |> Kernel.++(common_opts())
  end

  def mandatory_parameters(analyzed) do
    mandatory = Enum.reject(analyzed, &par_optional?/1)

    names = Enum.map(mandatory, fn [name | _] -> {name, [line: __ENV__.line], nil} end)

    mand_atoms = Enum.map(names, &extract_param_name/1)
    mand_values = Enum.map(mand_atoms, &nid/1)

    body = Enum.zip(mand_atoms, mand_values)

    {names, body}
  end

  def optional_parameters(analyzed) do
    optionals = Enum.filter(analyzed, &par_optional?/1)

    optional_types = Enum.map(optionals, fn [name, types, _desc, :optional] -> {name, types} end)
    optional_names = Enum.map(optionals, fn [name, _, _, _] -> name end)

    {optional_names, optional_types}
  end

  def file_parameters(analyzed) do
    direct_files =
      analyzed
      |> Enum.filter(fn [_n, t | _] -> Enum.any?(t, &(&1 == :file or &1 == :file_content)) end)
      |> Enum.map(fn
        [n, _t, _d] -> {nid(n), Atom.to_string(n)}
        [n, _t, _d, :optional] -> n
      end)

    media_files =
      analyzed
      |> Enum.filter(fn [_n, t | _] -> Enum.any?(t, &has_input_media_type?/1) end)
      |> Enum.map(fn
        [n, _t, _d] -> {:input_media, n}
        [n, _t, _d, :optional] -> {:input_media, n}
      end)

    direct_files ++ media_files
  end

  defp has_input_media_type?({:array, types}) when is_list(types) do
    Enum.any?(types, &input_media_alias?/1)
  end

  defp has_input_media_type?({:array, type}), do: input_media_alias?(type)

  defp has_input_media_type?(type), do: input_media_alias?(type)

  defp input_media_alias?({:__aliases__, _, parts}) do
    name = parts |> List.last() |> Atom.to_string()
    String.starts_with?(name, "InputMedia") or String.starts_with?(name, "InputPaidMedia")
  end

  defp input_media_alias?(_), do: false

  def type_to_spec(:string), do: {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}

  def type_to_spec(:enum), do: {{:., [], [{:__aliases__, [alias: false], [:Enum]}, :t]}, [], []}

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
    adapter_opts: :keyword,
    bot: :atom,
    token: :string,
    debug: :boolean,
    check_params: :boolean
  ]
  defp common_opts do
    Enum.map(@common_opts, fn {k, v} -> {k, type_to_spec(v)} end)
  end

  defp parameter_type_spec(n, t) when is_atom(n), do: {:"::", [], [type_to_spec(n), t]}
  defp parameter_type_spec(n, t), do: {:"::", [], [n, t]}

  defp nid(x), do: {x, [], nil}

  defp par_optional?([_n, _t, _d, :optional]), do: true
  defp par_optional?(_), do: false

  defp extract_param_name(name) when is_atom(name), do: name
  defp extract_param_name({name, _line, nil}), do: name
  defp extract_param_name({:\\, _line, [{name, _line2, nil}, nil]}), do: name

  # MODEL helpers

  def params_to_decode_as(params) do
    params
    |> Stream.map(fn [k, v | _] -> {k, v} end)
    |> Stream.map(fn {k, [v | _]} -> {k, param_to_decode_as(v)} end)
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

  def params_descriptions(params) do
    params
    |> Enum.sort_by(&par_optional?/1)
    |> Enum.map(fn
      [k, _, desc] -> {k, desc}
      [k, _, desc, :optional] -> {"#{k} (optional)", desc}
    end)
  end

  def struct_type_specs([], acc), do: acc

  def struct_type_specs([[id, t, _] | xs], acc) do
    act = acc ++ [{id, type_to_spec(t)}]

    struct_type_specs(xs, act)
  end

  def struct_type_specs([[id, t, _, :optional] | xs], acc) do
    act = acc ++ [{id, {:|, [], [type_to_spec(t), nil]}}]

    struct_type_specs(xs, act)
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
