defmodule ExGram.Macros.Executer do
  @moduledoc """
  Executer for the method macro, it takes care of checking the parameters, fetching the token, building the path and body, and calling the adapter.
  """

  require Logger

  # credo:disable-for-next-line
  def execute_method(
        name,
        verb,
        body,
        file_parameters,
        returned_type,
        ops,
        method_ops,
        mandatory_types,
        optional_types
      ) do
    adapter =
      Keyword.get_lazy(ops, :adapter, fn ->
        ExGram.Config.get(:ex_gram, :adapter, ExGram.Adapter.Tesla)
      end)

    token = ExGram.Token.fetch(ops)

    debug = Keyword.get(ops, :debug, false)

    check_params? =
      Keyword.get_lazy(ops, :check_params, fn ->
        ExGram.Config.get(:ex_gram, :check_params, true)
      end)

    with {:token, token} when is_binary(token) <- {:token, token},
         {:params, :ok} <-
           {:params, check_params(check_params?, mandatory_types, method_ops, optional_types)} do
      path = "/bot#{token}/#{name}"

      body =
        body
        |> Keyword.merge(method_ops)
        |> Enum.into(%{})
        |> clean_body()
        |> body_with_files(file_parameters)

      if debug, do: Logger.info("Path: #{inspect(path)}\nbody: #{inspect(body)}")

      result = adapter.request(verb, path, body)

      case result do
        {:ok, body} ->
          {:ok, process_result(body, returned_type)}

        {:error, error} ->
          {:error, error}
      end
    else
      {:token, _} ->
        message =
          "No token available in the request, make sure you have the token setup on the config or you used the parameter \"token\" or \"bot\" correctly"

        {:error,
         %ExGram.Error{
           message: message
         }}

      {:params, {:error, msg}} ->
        {:error, %ExGram.Error{message: msg}}
    end
  end

  defp body_with_files(body, file_parts) do
    file_parts =
      file_parts
      |> Enum.map(fn
        {v, p} -> {v, p}
        keyw -> {body[keyw], Atom.to_string(keyw)}
      end)
      |> Enum.filter(fn
        {parameter, _} when is_tuple(parameter) -> elem(parameter, 0) in [:file, :file_content]
        _ -> false
      end)
      |> Enum.map(fn
        {{:file, path}, partname} ->
          {:file, partname, path}

        {{:file_content, content, filename}, partname} ->
          {:file_content, partname, content, filename}
      end)

    create_multipart(body, file_parts)
  end

  defp to_size_string(true), do: "true"
  defp to_size_string(false), do: "false"
  defp to_size_string(x) when is_binary(x), do: x
  defp to_size_string(x) when is_integer(x), do: Integer.to_string(x)
  # This is usefull to encode automatically
  defp to_size_string(x) when is_map(x), do: encode(x)
  defp to_size_string(_), do: raise("Not sizable!")

  defp encode(%{__struct__: _} = x) do
    x
    |> Map.from_struct()
    |> clean_body()
    |> ExGram.Encoder.encode!()
  end

  defp encode(x) when is_map(x) or is_list(x), do: ExGram.Encoder.encode!(x)
  defp encode(x), do: x

  defp clean_body(%{__struct__: _} = m) do
    m |> Map.from_struct() |> clean_body()
  end

  defp clean_body(map) when is_map(map) do
    for {k, v} <- map, not is_nil(v), into: %{}, do: {k, clean_body(v)}
  end

  defp clean_body(m) when is_list(m), do: Enum.map(m, &clean_body/1)
  defp clean_body(m), do: m

  defp process_result(list, [t]), do: Enum.map(list, &process_result(&1, t))

  defp process_result(elem, :integer), do: elem
  defp process_result(elem, :string), do: elem
  defp process_result(elem, true), do: elem

  defp process_result(elem, t) when is_atom(t) do
    struct(t, elem)
  end

  defp process_result(elem, _t), do: elem

  defp create_multipart(body, []), do: body

  defp create_multipart(body, fileparts) do
    filepart_names = Enum.map(fileparts, &elem(&1, 1)) |> Enum.map(&String.to_atom/1)

    restparts =
      body
      |> Map.drop(filepart_names)
      |> Map.to_list()
      |> Enum.map(fn {name, value} ->
        {Atom.to_string(name), to_size_string(value)}
      end)

    parts = fileparts ++ restparts

    {:multipart, parts}
  end

  defp check_params(false, _mandatory, _optional, _optional_types), do: :ok

  defp check_params(true, mandatory, optional, optional_types) do
    mandatory_checks = mandatory |> ExGram.Macros.Checker.check_types() |> mandatory_errors()

    optional =
      Enum.map(optional, fn {key, value} -> {value, Keyword.get(optional_types, key), key} end)

    optional_checks =
      optional
      |> Enum.map(fn {value, types, _key} -> [value, types] end)
      |> ExGram.Macros.Checker.check_types()
      |> optional_errors(optional)

    case {mandatory_checks, optional_checks} do
      {:ok, :ok} -> :ok
      {:ok, msg} -> {:error, msg}
      {msg, :ok} -> {:error, msg}
      {msg, msg2} -> {:error, "#{msg}\n#{msg2}"}
    end
  end

  defp mandatory_errors(:ok), do: :ok

  defp mandatory_errors({:error, errors}) do
    msg =
      Enum.map(errors, fn {{value, types}, index} ->
        expected_type_msg(index, types, value)
      end)
      |> Enum.join(", ")

    "Mandatory parameter types don't match: #{msg}"
  end

  defp optional_errors(:ok, _optional), do: :ok

  defp optional_errors({:error, errors}, optional) do
    msg =
      Enum.map(errors, fn {{value, types}, index} ->
        {_, _, name} = Enum.at(optional, index)
        expected_type_msg(name, types, value)
      end)
      |> Enum.join(", ")

    "Optional parameter types don't match: #{msg}"
  end

  defp expected_type_msg(name, types, value) do
    "parameter #{name} expected #{inspect(types)} but got #{inspect(value)}"
  end
end
