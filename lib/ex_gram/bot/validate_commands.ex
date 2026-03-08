defmodule ExGram.Bot.ValidateCommands do
  @moduledoc """
  Compile-time validation for bot command definitions.
  """

  @valid_scope_atoms [:default, :all_private_chats, :all_group_chats, :all_chat_administrators]

  def validate!(commands) do
    Enum.each(commands, fn command ->
      cmd = command[:command]
      opts = command[:opts]

      if opts != [] and !opts[:description] do
        raise ArgumentError, "Missing :description for /#{cmd}"
      end

      if opts[:description] do
        validate_scopes!(cmd, opts[:scopes])
      end
    end)
  end

  defp validate_scopes!(_cmd, nil), do: :ok
  defp validate_scopes!(_cmd, []), do: :ok

  defp validate_scopes!(cmd, scopes) when is_list(scopes) do
    Enum.each(scopes, &validate_scope!(cmd, &1))
  end

  defp validate_scope!(_cmd, scope) when scope in @valid_scope_atoms, do: :ok

  defp validate_scope!(cmd, {:chat, opts}), do: validate_scope_opts!(cmd, :chat, opts, [:chat_ids])

  defp validate_scope!(cmd, {:chat_administrators, opts}),
    do: validate_scope_opts!(cmd, :chat_administrators, opts, [:chat_ids])

  defp validate_scope!(cmd, {:chat_member, opts}),
    do: validate_scope_opts!(cmd, :chat_member, opts, [:chat_id, :user_ids])

  defp validate_scope!(cmd, scope), do: raise(ArgumentError, "Unknown scope #{inspect(scope)} for /#{cmd}")

  defp validate_scope_opts!(cmd, scope, opts, required_keys) when is_list(opts) do
    Enum.each(required_keys, fn key ->
      case Keyword.fetch(opts, key) do
        :error ->
          raise ArgumentError, "Missing :#{key} in :#{scope} scope for /#{cmd}"

        {:ok, value} when key in [:chat_ids, :user_ids] and not is_list(value) ->
          raise ArgumentError, ":#{key} must be a list in :#{scope} scope for /#{cmd}"

        {:ok, _} ->
          :ok
      end
    end)
  end

  defp validate_scope_opts!(cmd, _scope, opts, _required_keys) do
    raise ArgumentError,
          "scope options must be a keyword list, got: #{inspect(opts)} for /#{cmd}"
  end
end
