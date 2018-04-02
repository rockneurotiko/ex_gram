defmodule Telex.Macros do
  require Logger

  def transform_param({:{}, line, [{name, _line, nil}]}), do: {{name, line, nil}, [name, [:any]]}

  def transform_param({:{}, line, [{name, _line, nil}, types, :optional]}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def transform_param({name, _line, nil} = full), do: {full, [name, [:any]]}

  def transform_param({{name, line, nil}, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, [:any], :optional]}

  def transform_param({{name, line, nil}, types}), do: {{name, line, nil}, [name, types]}

  def transform_param({{name, line, nil}, types, :optional}),
    do: {{:\\, line, [{name, line, nil}, nil]}, [name, types, :optional]}

  def extract_name({name, _line, nil}), do: name
  def extract_name({:\\, _line, [{name, _line2, nil}, nil]}), do: name

  def orT(x, y), do: {:|, [], [x, y]}

  def nameAssignT(n, t) when is_atom(n), do: {:::, [], [type_to_spec(n), t]}
  def nameAssignT(n, t), do: {:::, [], [n, t]}

  def type_to_spec(:string),
    do: {{:., [], [{:__aliases__, [alias: false], [:String]}, :t]}, [], []}

  def type_to_spec(:file), do: {:file, type_to_spec(:string)}
  def type_to_spec({:array, t}), do: {:list, [], [type_to_spec(t)]}
  def type_to_spec(:int), do: type_to_spec(:integer)
  def type_to_spec(:bool), do: type_to_spec(:boolean)

  def type_to_spec({:__aliases__, _a, _t} = f) do
    quote do
      Telex.Model.unquote(f).t
    end
  end

  def type_to_spec(t) when is_atom(t), do: {t, [], Elixir}

  def types_list_to_spec([e1, e2 | rest]) do
    orT(type_to_spec(e1), types_list_to_spec([e2 | rest]))
  end

  def types_list_to_spec([e1]) do
    type_to_spec(e1)
  end

  def types_list_to_spec([]) do
    type_to_spec(:any)
  end

  def nid(x), do: {x, [], nil}

  def check_type(:integer, x), do: is_integer(x)
  def check_type(:string, x), do: is_bitstring(x)
  def check_type(:boolean, x), do: is_boolean(x)
  def check_type(:float, x), do: is_float(x)
  # TODO?
  def check_type(:file, {:file, _p}), do: true
  def check_type(:file, _o), do: false

  def check_type({:array, t}, x) do
    is_list(x) &&
      case x do
        [] ->
          true

        [e | _] ->
          check_type(t, e)
      end
  end

  def check_type(:any, _x), do: true

  def check_type(t1, %{__struct__: t2}) do
    t1 == t2 ||
      (
        t2s = Atom.to_string(t2)

        t2 =
          if String.starts_with?(t2s, "Elixir.Telex.Model.") do
            name = String.split(t2s, ".") |> List.last()
            String.to_atom("Elixir.#{name}")
          else
            t2
          end

        t1 == t2
      )
  end

  # def check_type(t1, %{__struct__: t2}), do: t1 == t2
  def check_type(%{}, x), do: is_map(x)

  def check_all_types([x, types]), do: Enum.any?(types, &check_type(&1, x))
  def check_all_types([x, types, :optional]), do: x == nil or check_all_types({x, types})
  def check_all_types({x, types}), do: check_all_types([x, types])
  def check_all_types({x, types, :optional}), do: check_all_types([x, types, :optional])

  def check_all_types_ignore_opt([_x, _types, :optional]), do: true
  def check_all_types_ignore_opt({_x, _types, :optional}), do: true
  def check_all_types_ignore_opt(x), do: check_all_types(x)

  def type_to_macrot([n, t]), do: [nid(n), t]
  def type_to_macrot([n, t, o]), do: [nid(n), t, o]

  def partition_optional_parameter({_, [_n, _t, :optional]}), do: true
  def partition_optional_parameter(_), do: false

  def is_par_optional([_n, _t, :optional]), do: true
  def is_par_optional(_), do: false

  def is_multi([]), do: false
  def is_multi([_x | _]), do: true

  def to_size_string(true), do: "true"
  def to_size_string(false), do: "false"
  def to_size_string(x) when is_binary(x), do: x
  def to_size_string(x) when is_integer(x), do: Integer.to_string(x)
  # This is usefull to encode automatically
  def to_size_string(x) when is_map(x), do: encode(x)
  def to_size_string(_), do: raise("Not sizable!")

  def filter_map(%{__struct__: _} = m) do
    m |> Map.from_struct() |> filter_map
  end

  def filter_map(m) when is_map(m) do
    m
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.map(fn {key, value} ->
      cond do
        is_list(value) ->
          {key, Enum.map(value, &filter_map/1)}

        is_map(value) ->
          {key, filter_map(value)}

        true ->
          {key, value}
      end
    end)
    |> Enum.into(%{})
  end

  def filter_map(m) when is_list(m), do: Enum.map(m, &filter_map/1)
  def filter_map(m), do: m

  def encode(%{__struct__: _} = x) do
    x
    |> Map.from_struct()
    |> filter_map
    |> Poison.encode!()
  end

  def encode(x) when is_map(x) or is_list(x), do: Poison.encode!(x)
  def encode(x), do: x

  def encode_body(body) do
    if is_map(body) do
      body
      |> Enum.map(fn {key, value} -> {key, encode(value)} end)
      |> Enum.into(%{})
    else
      body
    end
  end

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

  def maybe_log(maybe, level \\ :debug, x)
  def maybe_log(true, level, x), do: Logger.log(level, fn -> inspect(x) end)
  def maybe_log(_, _, _), do: :ok

  defmacro model(name, params) do
    tps = struct_types(params)

    initials =
      tps
      |> Enum.map(fn {id, _t} -> {id, nil} end)

    quote do
      defmodule unquote(name) do
        defstruct unquote(initials)
        @type t :: %unquote(name){unquote_splicing(tps)}
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

    mand_names = mand_par |> Enum.map(&extract_name/1)
    mand_vnames = mand_names |> Enum.map(&nid/1)
    mand_body = Enum.zip(mand_names, mand_vnames)

    result_transformer =
      case returned do
        [{:__aliases__, _l, _t} = t] ->
          quote do
            (fn l -> Enum.map(l, &(struct(unquote(t)) |> Map.merge(&1))) end).()
          end

        {:__aliases__, _l, _t} = t ->
          quote do
            (fn x ->
               struct(unquote(t)) |> Map.merge(x)
             end).()
          end

        _ ->
          quote do
            (fn x -> x end).()
          end
      end

    # Change Telex.Model.Type for Telex.Model.Type.t
    returned =
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

    putbody =
      case verb do
        :post -> :put_req_body
        _ -> :put_query_string
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

    quote do
      # Safe method
      @doc """
      TODO: Do documentation
      """
      @spec unquote(fname)(unquote_splicing(types_mand_spec), ops :: unquote(types_opt_spec)) ::
              {:ok, unquote(returned)}
              | {:error, Maxwell.Error.t()}
      def unquote(fname)(unquote_splicing(mand_par), ops \\ []) do
        check_params = Keyword.get(ops, :check_params)

        checks =
          check_params and
            Enum.map(unquote(types_mand), &check_all_types_ignore_opt/1)
            |> Enum.all?()

        token =
          case {Keyword.get(ops, :token), Keyword.get(ops, :bot)} do
            {nil, nil} ->
              Telex.Config.get(:telex, :token)

            {token, nil} ->
              token

            {nil, bot} ->
              [{_, token}] = Registry.lookup(Registry.Telex, bot)
              token
          end

        debug = Keyword.get(ops, :debug, false)

        # Remove not valids
        ops = Keyword.take(ops, unquote(opt_par))

        ops_checks =
          check_params or
            ops
            |> Enum.map(fn {key, value} ->
              check_all_types({value, Keyword.get(unquote(opt_par_types), key)})
            end)
            |> Enum.all?()

        if check_params and (!checks || !ops_checks) do
          {
            :error,
            "Some invariant of the method #{unquote(name)} was not succesful, check the documentation"
          }
        else
          body =
            unquote(mand_body)
            |> Keyword.merge(ops)
            |> Enum.into(%{})

          body =
            if unquote(have_multipart) do
              # It may have a file to upload, let's check it!

              # Extract the value and part name (it can be from parameter or ops)
              {vn, partname} =
                case Enum.at(unquote(multi_full), 0) do
                  {v, p} -> {v, p}
                  keyw -> {ops[keyw], Atom.to_string(keyw)}
                end

              case vn do
                {:file, path} ->
                  # It's a file, let's build the multipart data for maxwell post
                  disposition = {"form-data", [{"name", partname}, {"filename", path}]}
                  # File part
                  fpath = {:file, path, disposition, []}

                  # Encode all the other parts in the proper way
                  restparts =
                    body
                    |> Map.delete(String.to_atom(partname))
                    |> Map.to_list()
                    |> Enum.map(fn {name, value} ->
                      {Atom.to_string(name), to_size_string(value)}
                    end)

                  parts = [fpath | restparts]

                  {:multipart, parts}

                _x ->
                  body
              end
            else
              # No possible file in this method, keep moving
              body
            end

          lambda_putbody = fn x ->
            apply(Maxwell.Conn, unquote(putbody), [x, encode_body(body)])
          end

          lambda_callverb = fn x -> apply(Telex, unquote(verb), [x]) end

          path = "/bot#{token}/#{unquote(name)}"
          # IO.puts("Path: #{inspect path}\nbody: #{inspect body}")

          result =
            new()
            |> put_path(path)
            |> lambda_putbody.()
            |> lambda_callverb.()

          case result do
            {:ok, %Maxwell.Conn{status: status} = new_conn} when status in 200..299 ->
              maybe_log(debug, new_conn)
              parsed = new_conn |> get_resp_body(:result) |> unquote(result_transformer)
              {:ok, parsed}

            {:ok, new_conn} ->
              error = Maxwell.Error.exception({__MODULE__, :response_status_not_match, new_conn})
              {:error, error}

            {:error, reason, new_conn} ->
              error = Maxwell.Error.exception({__MODULE__, reason, new_conn})
              {:error, error}

            {:error, reason} ->
              error = Maxwell.Error.exception({__MODULE__, reason, result})
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
            ) :: unquote(returned)
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
