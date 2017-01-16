defmodule Telex.Dsl.Base do
  @callback test(Telex.Model.Update.t) :: boolean
  @callback execute(Telex.Model.Update.t) :: any


  def extract_name({:__aliases__, _, [name]}), do: Atom.to_string(name)
  def extract_name(name) when is_atom(name), do: Atom.to_string(name)
  def extract_name(name) when is_bitstring(name), do: name

  def module_name(base, name) when is_atom(base) do
    name = extract_name name
    String.to_atom("#{Atom.to_string(base)}.#{String.to_atom(name)}")
  end

  def module_callback(name, use_base, callback) do
    module = module_name use_base, name

    quote do
      defmodule unquote(module) do
        use unquote(use_base)

        def execute(m), do: unquote(callback).(m)
      end

      @dispatchers unquote(module)
    end
  end

  def module_do_macro(name, module, block, macro, varname) do
    fname = Telex.Dsl.Base.extract_name(name) |> String.downcase |> String.to_atom

    varname = {varname, [], Elixir}

    quote do
      def unquote(fname)(var!(unquote(varname))), do: unquote(block)

      unquote(macro)(unquote(fname), &unquote(module).unquote(fname)/1)
    end
  end
end
