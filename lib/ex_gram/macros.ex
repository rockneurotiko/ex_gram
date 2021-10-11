defmodule ExGram.Macros do
  @moduledoc """
  `model/2` and `method/4` macros to build the API
  """

  import __MODULE__.Helpers

  defmacro model(name, params, description) do
    tps = struct_type_specs(params)

    initials =
      tps
      |> Enum.map(fn {id, _t} -> {id, nil} end)

    dca = params_to_decode_as(params)

    quote do
      defmodule unquote(name) do
        @moduledoc """
        #{unquote(description)}

        Check the documentation of this model in https://core.telegram.org/bots/api##{unquote(name) |> inspect() |> String.split(".") |> Enum.at(-1) |> String.downcase()}
        """
        defstruct unquote(initials)
        @type t :: %unquote(name){unquote_splicing(tps)}

        def decode_as() do
          %unquote(name){unquote_splicing(dca)}
        end
      end
    end
  end

  defmacro method(verb, name, params, returned, description) do
    fname =
      Macro.underscore(name)
      |> String.to_atom()

    # fnametest =
    #   "#{Macro.underscore(name)}_test"
    #   |> String.to_atom

    fname_exception =
      "#{Macro.underscore(name)}!"
      |> String.to_atom()

    analyzed = params |> Enum.map(&analyze_param/1)

    types_mand_value = mandatory_value_type(analyzed)
    types_mand_spec = mandatory_type_specs(analyzed)

    types_opt_spec = optional_type_specs(analyzed)

    {mandatory_parameters, mandatory_body} = mandatory_parameters(analyzed)

    {opt_par, opt_par_types} = optional_parameters(analyzed)

    returned_type_spec = type_to_spec(returned)

    file_parameters = file_parameters(analyzed)

    quote location: :keep do
      # Safe method
      @doc """
      #{unquote(description)}

      Check the documentation of this method in https://core.telegram.org/bots/api##{String.downcase(unquote(name))}
      """
      @spec unquote(fname)(unquote_splicing(types_mand_spec), options :: unquote(types_opt_spec)) ::
              {:ok, unquote(returned_type_spec)}
              | {:error, ExGram.Error.t()}
      def unquote(fname)(unquote_splicing(mandatory_parameters), options \\ []) do
        name = unquote(name)
        verb = unquote(verb)
        mandatory_body = unquote(mandatory_body)
        file_parameters = unquote(file_parameters)
        returned = unquote(returned)
        method_ops = Keyword.take(options, unquote(opt_par))
        mandatory_types = unquote(types_mand_value)
        optional_types = unquote(opt_par_types)

        ExGram.Macros.Executer.execute_method(
          name,
          verb,
          mandatory_body,
          file_parameters,
          returned,
          options,
          method_ops,
          mandatory_types,
          optional_types
        )
      end

      # Unsafe method
      @doc """
      Unsafe version of #{unquote(fname)}. It will return the response or raise in case of error.

      #{unquote(description)}

      Check the documentation of this method in https://core.telegram.org/bots/api##{String.downcase(unquote(name))}
      """
      @spec unquote(fname_exception)(
              unquote_splicing(types_mand_spec),
              ops :: unquote(types_opt_spec)
            ) :: unquote(returned_type_spec)
      def unquote(fname_exception)(unquote_splicing(mandatory_parameters), ops \\ []) do
        case unquote(fname)(unquote_splicing(mandatory_parameters), ops) do
          {:ok, result} -> result
          {:error, error} -> raise error
        end
      end
    end
  end
end
