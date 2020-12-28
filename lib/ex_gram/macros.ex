defmodule ExGram.Macros do
  import __MODULE__.Helpers

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

  @common_opts [
                 adapter: :atom,
                 bot: :atom,
                 token: :string,
                 debug: :boolean,
                 check_params: :boolean
               ]
               |> Enum.map(fn {k, v} -> {k, type_to_spec(v)} end)

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
      |> Kernel.++(@common_opts)

    {opt_par, mand_par} =
      analyzed
      |> Enum.split_with(&partition_optional_parameter/1)

    opt_par_types = opt_par |> Enum.map(fn {_n, t} -> {Enum.at(t, 0), Enum.at(t, 1)} end)
    opt_par = opt_par |> Enum.map(fn {_n, t} -> Enum.at(t, 0) end)
    mand_par = mand_par |> Enum.map(fn {n, _t} -> n end)

    mand_names = mand_par |> Enum.map(&extract_param_name/1)
    mand_vnames = mand_names |> Enum.map(&nid/1)
    mand_body = Enum.zip(mand_names, mand_vnames)

    returned_type_spec = type_to_spec(returned)

    multi_full =
      analyzed
      |> Enum.map(fn {_n, types} -> types end)
      |> Enum.filter(fn [_n, t | _] -> Enum.any?(t, &(&1 == :file or &1 == :file_content)) end)
      |> Enum.map(fn
        [n, _t] -> {nid(n), Atom.to_string(n)}
        [n, _t, :optional] -> n
      end)

    quote location: :keep do
      # Safe method
      @doc """
      Check the documentation of this method in https://core.telegram.org/bots/api##{
        String.downcase(unquote(name))
      }
      """
      @spec unquote(fname)(unquote_splicing(types_mand_spec), options :: unquote(types_opt_spec)) ::
              {:ok, unquote(returned_type_spec)}
              | {:error, ExGram.Error.t()}
      def unquote(fname)(unquote_splicing(mand_par), options \\ []) do
        name = unquote(name)
        verb = unquote(verb)
        mand_body = unquote(mand_body)
        multi_full = unquote(multi_full)
        returned = unquote(returned)
        method_ops = Keyword.take(options, unquote(opt_par))
        mandatory_types = unquote(types_mand)
        optional_types = unquote(opt_par_types)

        ExGram.Macros.Executer.execute_method(
          name,
          verb,
          mand_body,
          multi_full,
          returned,
          options,
          method_ops,
          mandatory_types,
          optional_types
        )
      end

      # Unsafe method
      @doc """
      TODO: Do documentation
      """
      @spec unquote(fname_exception)(
              unquote_splicing(types_mand_spec),
              ops :: unquote(types_opt_spec)
            ) :: unquote(returned_type_spec)
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
