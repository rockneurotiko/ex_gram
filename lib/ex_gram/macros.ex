defmodule ExGram.Macros do
  @adapter ExGram.Config.get(:ex_gram, :adapter, ExGram.Adapter.Tesla)

  import __MODULE__.Helpers

  def nameAssignT(n, t) when is_atom(n), do: {:::, [], [type_to_spec(n), t]}
  def nameAssignT(n, t), do: {:::, [], [n, t]}

  def nid(x), do: {x, [], nil}

  def type_to_macrot([n, t]), do: [nid(n), t]
  def type_to_macrot([n, t, o]), do: [nid(n), t, o]

  def partition_optional_parameter({_, [_n, _t, :optional]}), do: true
  def partition_optional_parameter(_), do: false

  def is_par_optional([_n, _t, :optional]), do: true
  def is_par_optional(_), do: false

  defmacro model(name, params) do
    tps = struct_types(params)

    initials =
      tps
      |> Enum.map(fn {id, _t} -> {id, nil} end)

    dca = params_to_decode(params)

    quote do
      defmodule unquote(name) do
        defstruct unquote(initials)
        @type t :: %unquote(name){unquote_splicing(tps)}

        def decode_as() do
          %unquote(name){unquote_splicing(dca)}
        end
      end
    end
  end

  defmacro method(verb, name, params, returned) do
    fname =
      Macro.underscore(name)
      |> String.to_atom()

    # fnametest =
    #   "#{Macro.underscore(name)}_test"
    #   |> String.to_atom

    fname_exception =
      "#{Macro.underscore(name)}!"
      |> String.to_atom()

    analyzed = params |> Enum.map(&transform_param/1)

    {types_opt, types_mand} =
      analyzed
      |> Enum.map(fn {_n, types} -> types end)
      |> Enum.map(&type_to_macrot/1)
      |> Enum.split_with(&is_par_optional(&1))

    types_mand_spec =
      types_mand
      |> Enum.map(fn [{n, [], nil}, ts] -> nameAssignT(n, types_list_to_spec(ts)) end)

    types_opt_spec =
      types_opt
      |> Enum.map(fn [{n, [], nil}, ts, :optional] -> {n, types_list_to_spec(ts)} end)

    {opt_par, mand_par} =
      analyzed
      |> Enum.split_with(&partition_optional_parameter/1)

    opt_par_types = opt_par |> Enum.map(fn {_n, t} -> {Enum.at(t, 0), Enum.at(t, 1)} end)
    opt_par = opt_par |> Enum.map(fn {_n, t} -> Enum.at(t, 0) end)
    mand_par = mand_par |> Enum.map(fn {n, _t} -> n end)

    mand_names = mand_par |> Enum.map(&extract_param_name/1)
    mand_vnames = mand_names |> Enum.map(&nid/1)
    mand_body = Enum.zip(mand_names, mand_vnames)

    # Change ExGram.Model.Type for ExGram.Model.Type.t
    returned_type =
      case returned do
        [{:__aliases__, _l, _t} = t] ->
          quote do
            [unquote(t).t]
          end

        {:__aliases__, _l, _t} = t ->
          quote do
            unquote(t).t
          end

        _ ->
          returned
      end

    multi_full =
      analyzed
      |> Enum.map(fn {_n, types} -> types end)
      |> Enum.filter(fn [_n, t | _] -> Enum.any?(t, &(&1 == :file)) end)
      |> Enum.map(fn
        [n, _t] -> {nid(n), Atom.to_string(n)}
        [n, _t, :optional] -> n
      end)

    have_multipart = Enum.count(multi_full) > 0

    quote location: :keep do
      # Safe method
      @doc """
      Check the documentation of this method in https://core.telegram.org/bots/api##{
        String.downcase(unquote(name))
      }
      """
      @spec unquote(fname)(unquote_splicing(types_mand_spec), ops :: unquote(types_opt_spec)) ::
              {:ok, unquote(returned_type)}
              | {:error, ExGram.Error.t()}
      def unquote(fname)(unquote_splicing(mand_par), ops \\ []) do
        adapter = Keyword.get(ops, :adapter, unquote(@adapter))
        config_check_params = ExGram.Config.get(:ex_gram, :check_params, true)
        token = ExGram.Token.fetch(ops)
        debug = Keyword.get(ops, :debug, false)

        # Remove not valids
        ops = Keyword.take(ops, unquote(opt_par))

        check_params? = Keyword.get(ops, :check_params, config_check_params)

        if !check_params(check_params?, unquote(types_mand), ops, unquote(opt_par_types)) do
          {
            :error,
            "Some invariant of the method #{unquote(name)} was not succesful, check the documentation"
          }
        else
          verb = unquote(verb)
          name = unquote(name)
          mand_body = unquote(mand_body)
          have_multipart = unquote(have_multipart)
          multi_full = unquote(multi_full)
          returned_type = unquote(returned)
          # result_transformer = unquote(result_transformer)

          body =
            mand_body
            |> Keyword.merge(ops)
            |> Enum.into(%{})
            |> ExGram.Macros.Helpers.clean_body()

          body =
            if have_multipart do
              # It may have a file to upload, let's check it!

              # Extract the value and part name (it can be from parameter or ops)
              {vn, partname} =
                case Enum.at(multi_full, 0) do
                  {v, p} -> {v, p}
                  keyw -> {ops[keyw], Atom.to_string(keyw)}
                end

              case vn do
                {:file, path} ->
                  file_part = {:file, partname, path}

                  # Encode all the other parts in the proper way
                  restparts =
                    body
                    |> Map.delete(String.to_atom(partname))
                    |> Map.to_list()
                    |> Enum.map(fn {name, value} ->
                      {Atom.to_string(name), to_size_string(value)}
                    end)

                  parts = [file_part | restparts]

                  {:multipart, parts}

                _x ->
                  body
              end
            else
              # No possible file in this method, keep moving
              body
            end

          path = "/bot#{token}/#{name}"
          # IO.puts("Path: #{inspect(path)}\nbody: #{inspect(body)}")

          result = adapter.request(verb, path, body)

          case result do
            {:ok, body} ->
              {:ok, body |> ExGram.Macros.Helpers.process_result(returned_type)}

            {:error, error} ->
              {:error, error}
          end
        end
      end

      # Unsafe method
      @doc """
      TODO: Do documentation
      """
      @spec unquote(fname_exception)(
              unquote_splicing(types_mand_spec),
              ops :: unquote(types_opt_spec)
            ) :: unquote(returned_type)
      def unquote(fname_exception)(unquote_splicing(mand_par), ops \\ []) do
        # TODO use own errors
        case unquote(fname)(unquote_splicing(mand_par), ops) do
          {:ok, result} -> result
          {:error, error} -> raise error
        end
      end
    end
  end
end
