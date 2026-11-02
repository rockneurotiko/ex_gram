defmodule ExGram.Macros do
  @moduledoc """
  `model/3`, `union_type/2` and `method/5` macros to build the API
  """

  import __MODULE__.Helpers

  defmacro model(name, params, description) do
    analyzed = analyze_params(params)
    tps = struct_type_specs(analyzed)

    initials =
      Enum.map(tps, fn {id, _t} -> {id, nil} end)

    dca = params_to_decode_as(analyzed)

    params_descriptions = params_descriptions(analyzed)

    short_name = name |> Macro.to_string() |> String.split(".") |> List.last() |> String.to_atom()

    quote do
      ExGram.Macros.register_shape(__MODULE__, unquote(short_name), unquote(Macro.escape(tps)))

      defmodule unquote(name) do
        @moduledoc """
        #{unquote(description)}

        Check the [documentation of this model on Telegram Bot API](https://core.telegram.org/bots/api##{unquote(name) |> inspect() |> String.split(".") |> Enum.at(-1) |> String.downcase()})

        #{Enum.map_join(unquote(params_descriptions), "\n", fn {k, v} -> "- `#{k}`: #{v}" end)}
        """
        defstruct unquote(initials)
        @type t :: %unquote(name){unquote_splicing(tps)}

        def decode_as do
          %unquote(name){unquote_splicing(dca)}
        end
      end
    end
  end

  @doc false
  def register_shape(module, name, fields) do
    shapes = Module.get_attribute(module, :ex_gram_shapes, %{})
    Module.put_attribute(module, :ex_gram_shapes, Map.put(shapes, name, fields))
  end

  @doc """
  Defines `@type t` of a model that is the union of other models (its subtypes)
  plus some extra types.

  Subtypes with exactly the same fields (names and types) are written as a single
  map type with the union of their struct names, instead of one remote type each:

      %{__struct__: Bold | Italic, type: String.t(), text: RichText.t()}

  It is the same set of values as `Bold.t() | Italic.t()`, but Dialyzer keeps in
  memory a fully expanded copy of every remote type used in a spec, so the
  alternatives that repeat the same fields make the contracts much bigger.
  """
  defmacro union_type(extra, subtypes) do
    parent = __CALLER__.module |> Module.split() |> Enum.drop(-1) |> Module.concat()
    shapes = Module.get_attribute(parent, :ex_gram_shapes, %{})
    names = for {:__aliases__, _, [name]} <- subtypes, do: name
    groups = Enum.group_by(names, fn name -> shapes |> Map.get(name) |> strip_meta() end)

    subtype_types =
      Enum.flat_map(names, fn name ->
        case {Map.get(shapes, name), Map.fetch!(groups, strip_meta(Map.get(shapes, name)))} do
          {nil, _} -> [quote(do: unquote(subtype_alias(name)).t())]
          {_, [^name]} -> [quote(do: unquote(subtype_alias(name)).t())]
          {fields, [^name | _] = group} -> [shared_shape_type(group, fields)]
          {_, _} -> []
        end
      end)

    type = union(extra ++ subtype_types)

    quote do
      @type t :: unquote(type)
    end
  end

  defp union(types), do: types |> Enum.reverse() |> Enum.reduce(&{:|, [], [&1, &2]})

  defp strip_meta(ast), do: Macro.prewalk(ast, &Macro.update_meta(&1, fn _ -> [] end))

  defp subtype_alias(name), do: {:__aliases__, [], [:ExGram, :Model, name]}

  defp shared_shape_type(group, fields) do
    {:%{}, [], [{:__struct__, group |> Enum.map(&subtype_alias/1) |> union()} | fields]}
  end

  defmacro method(verb, name, params, returned, description) do
    fname =
      name
      |> Macro.underscore()
      |> String.to_atom()

    # fnametest =
    #   "#{Macro.underscore(name)}_test"
    #   |> String.to_atom

    fname_exception =
      String.to_atom("#{Macro.underscore(name)}!")

    analyzed = analyze_params(params)

    types_mand_value = mandatory_value_type(analyzed)
    types_mand_spec = mandatory_type_specs(analyzed)

    types_opt_spec = optional_type_specs(analyzed)

    {mandatory_parameters, mandatory_body} = mandatory_parameters(analyzed)
    n_parameters = length(mandatory_parameters) + 1

    {opt_par, opt_par_types} = optional_parameters(analyzed)

    # Bot API 10.3 replaced the `receiver_user_id` / `callback_query_id` options with the
    # `ephemeral_message_parameters` struct on sendMessage and the other affected send* methods.
    # For those methods only, translate the legacy options into `ephemeral_message_parameters`
    # before they get filtered by `Keyword.take/2` below, so old callers keep working.
    ephemeral_legacy_translation =
      if :ephemeral_message_parameters in opt_par do
        quote do
          options = translate_ephemeral_legacy_options(options)
        end
      end

    returned_type_spec = type_to_spec(returned)

    file_parameters = file_parameters(analyzed)

    params_descriptions = params_descriptions(analyzed)

    quote location: :keep do
      # Safe method
      @doc """
      #{unquote(description)}

      Check the [documentation of this method on Telegram Bot API](https://core.telegram.org/bots/api##{String.downcase(unquote(name))})

      #{Enum.map_join(unquote(params_descriptions), "\n", fn {k, v} -> "- `#{k}`: #{v}" end)}
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
        unquote(ephemeral_legacy_translation)
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
      Unsafe version of `#{unquote(fname)}/#{unquote(n_parameters)}`. It will return the response or raise in case of error.

      #{unquote(description)}

      Check the [documentation of this method on Telegram Bot API](https://core.telegram.org/bots/api##{String.downcase(unquote(name))})
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
