defmodule ExGram.Config do
  @moduledoc """
  Configuration helper with environment variable support.

  This module provides `get/3` and `get_integer/3` functions that fetch values from
  application config, with special handling for `{:system, "VAR"}` tuples to read
  from environment variables.

  ## Example

      # In config.exs
      config :ex_gram, token: {:system, "BOT_TOKEN"}

      # At runtime
      ExGram.Config.get(:ex_gram, :token) # Reads from $BOT_TOKEN env var
  """

  @doc """
  Fetches a value from the config, or from the environment if `{:system, "VAR"}`
  is provided.

  An optional default value can be provided if desired.

  ## Examples

      iex> {test_var, expected_value} = System.get_env |> Enum.take(1) |> List.first
      ...> Application.put_env(:myapp, :test_var, {:system, test_var})
      ...> ^expected_value = #{__MODULE__}.get(:myapp, :test_var)
      ...> :ok
      :ok

      iex> Application.put_env(:myapp, :test_var2, 1)
      ...> 1 = #{__MODULE__}.get(:myapp, :test_var2)
      1

      iex> :default = #{__MODULE__}.get(:myapp, :missing_var, :default)
      :default
  """
  @spec get(atom, atom, term | nil) :: term
  def get(app, key, default \\ nil) when is_atom(app) and is_atom(key) do
    case Application.get_env(app, key) do
      {:system, env_var} ->
        get_env(env_var, default)

      {:system, env_var, preconfigured_default} ->
        get_env(env_var, preconfigured_default)

      nil ->
        default

      val ->
        val
    end
  end

  
  
  @doc """
  Fetches the configured value for `key` and returns it as an integer.
  
  If the stored value is already an integer it is returned. If the stored value is a string that can be parsed as an integer, the parsed integer is returned. If the value is missing or cannot be converted, the provided `default` is returned.
  
  ## Parameters
  
    - app: OTP application name.
    - key: configuration key.
    - default: integer or `nil` returned when the value is absent or not convertible to an integer.
  
  ## Returns
  
  The integer value from configuration or `default` when absent or non-convertible.
  """
  @spec get_integer(atom(), atom(), integer() | nil) :: integer
  def get_integer(app, key, default \\ nil) do
    case get(app, key, nil) do
      nil ->
        default

      n when is_integer(n) ->
        n

      n ->
        case Integer.parse(n) do
          {i, _} -> i
          :error -> default
        end
    end
  end

  defp get_env(env_var, default) do
    case System.get_env(env_var) do
      nil -> default
      val -> val
    end
  end
end
