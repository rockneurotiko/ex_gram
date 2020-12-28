defmodule ExGram.Macros.Executer do
  require Logger

  def execute_method(
        name,
        verb,
        body,
        multi_full,
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

    cond do
      is_nil(token) ->
        message =
          "No token available in the request, make sure you have the token setup on the config or you used the parameter \"token\" or \"bot\" correctly"

        {:error,
         %ExGram.Error{
           message: message
         }}

      !check_params(check_params?, mandatory_types, method_ops, optional_types) ->
        {
          :error,
          "Some invariant of the method #{name} was not succesful, check the documentation"
        }

      true ->
        body =
          body
          |> Keyword.merge(method_ops)
          |> Enum.into(%{})
          |> clean_body()

        # Extract the value and part name (it can be from method_ops)
        file_parts =
          Enum.map(multi_full, fn
            {v, p} -> {v, p}
            keyw -> {method_ops[keyw], Atom.to_string(keyw)}
          end)
          |> Enum.filter(&(not is_nil(elem(&1, 0))))
          |> Enum.map(fn
            {{:file, path}, partname} ->
              {:file, partname, path}

            {{:file_content, content, filename}, partname} ->
              {:file_content, partname, content, filename}
          end)

        body = create_multipart(body, file_parts)

        path = "/bot#{token}/#{name}"

        if debug, do: Logger.info("Path: #{inspect(path)}\nbody: #{inspect(body)}")

        result = adapter.request(verb, path, body)

        case result do
          {:ok, body} ->
            {:ok, ExGram.Macros.Helpers.process_result(body, returned_type)}

          {:error, error} ->
            {:error, error}
        end
    end
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

  defp check_params(false, _mandatory, _optional, _optional_types), do: true

  defp check_params(true, mandatory, optional, optional_types) do
    mandatory_checks = ExGram.Macros.Checker.check_types(mandatory)

    optional_checks =
      optional
      |> Enum.map(fn {key, value} -> [value, Keyword.get(optional_types, key)] end)
      |> ExGram.Macros.Checker.check_types()

    mandatory_checks and optional_checks
  end
end
