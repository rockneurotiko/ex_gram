defmodule ExGram.TestHelpers do
  @moduledoc """
  Helper functions for building test data structures.
  """

  alias ExGram.Model.CallbackQuery
  alias ExGram.Model.Chat
  alias ExGram.Model.InlineQuery
  alias ExGram.Model.Location
  alias ExGram.Model.Message
  alias ExGram.Model.Update
  alias ExGram.Model.User

  @doc """
  Generate a unique atom based on the test context and a prefix.
  
  ## Parameters
  
    - context: ExUnit test context map containing at least the `:test` atom name.
    - prefix: String used as the leading component of the generated name.
  
  ## Returns
  
    - An atom combining the prefix, a sanitized form of the test name, and a unique positive integer.
  """
  @spec unique_name(map(), String.t()) :: atom()
  def unique_name(context, prefix) do
    base = context.test |> Atom.to_string() |> String.replace(~r/[^a-z0-9]/i, "_")
    String.to_atom("#{prefix}_#{base}_#{System.unique_integer([:positive])}")
  end

  @doc """
  Create a unique bot name and a corresponding module atom for use in tests.
  
  ## Parameters
  
    - context: Test context (usually the `context` map provided by ExUnit) used to derive a unique base name.
  
  ## Returns
  
    - `{name, module}` tuple where `name` is a unique atom derived from the test context and `module` is a module-safe atom (e.g., `ExGram.TestHelpers.Bot_<name>`).
  """
  @spec unique_bot_name(map()) :: {atom(), module()}
  def unique_bot_name(context) do
    name = unique_name(context, "bot_test")
    module_name = Module.concat([ExGram.TestHelpers, String.to_atom("Bot_#{name}")])
    {name, module_name}
  end

  @doc """
  Create a User struct populated with sensible defaults for tests.
  
  The given `attrs` map is merged into the defaults, overriding any default fields.
  Defaults:
    - `:id` — unique positive integer
    - `:is_bot` — `false`
    - `:first_name` — `"Test"`
  
  ## Examples
  
      iex> build_user(%{first_name: "Alice"}).first_name
      "Alice"
  """
  @spec build_user(map()) :: User.t()
  def build_user(attrs \\ %{}) do
    defaults = %{
      id: System.unique_integer([:positive]),
      is_bot: false,
      first_name: "Test"
    }

    struct(User, Map.merge(defaults, attrs))
  end

  @doc """
  Creates a Chat struct with sensible defaults for use in tests.
  
  Defaults:
    - `id`: a unique positive integer
    - `type`: `"private"`
  
  ## Parameters
  
    - `attrs`: Map of fields to override the defaults.
  
  """
  @spec build_chat(map()) :: Chat.t()
  def build_chat(attrs \\ %{}) do
    defaults = %{
      id: System.unique_integer([:positive]),
      type: "private"
    }

    struct(Chat, Map.merge(defaults, attrs))
  end

  @doc """
  Builds a Message struct populated with sensible test defaults.
  
  Accepts an optional map of attributes to override default fields (for example: `:message_id`, `:date`, `:chat`, `:from`).
  
  ## Parameters
  
    - attrs: Map of fields to merge into the default message.
  
  ## Examples
  
      iex> msg = ExGram.TestHelpers.build_message(%{message_id: 1})
      iex> msg.message_id
      1
  
  """
  @spec build_message(map()) :: Message.t()
  def build_message(attrs \\ %{}) do
    defaults = %{
      message_id: System.unique_integer([:positive]),
      date: System.system_time(:second),
      chat: build_chat(),
      from: build_user()
    }

    struct(Message, Map.merge(defaults, attrs))
  end

  @doc """
  Constructs a test Update struct with sensible defaults that can be overridden.
  
  Defaults:
    - `update_id` — a unique positive integer generated via System.unique_integer/1.
  
  ## Parameters
  
    - attrs: map of fields to merge into the defaults (default: %{}).
  """
  @spec build_update(map()) :: Update.t()
  def build_update(attrs \\ %{}) do
    defaults = %{
      update_id: System.unique_integer([:positive])
    }

    struct(Update, Map.merge(defaults, attrs))
  end

  @doc """
  Create a CallbackQuery struct populated with sensible defaults for tests.
  
  The provided `attrs` map is merged into the default fields, allowing callers to override any default value (for example `:id`, `:from`, or `:chat_instance`).
  
  ## Parameters
  
    - attrs: Map of fields to override on the default CallbackQuery struct.
  
  ## Examples
  
      iex> build_callback_query(%{id: "cbq_custom"})
      %CallbackQuery{id: "cbq_custom", from: %User{}, chat_instance: "123"}
  
  """
  @spec build_callback_query(map()) :: CallbackQuery.t()
  def build_callback_query(attrs \\ %{}) do
    defaults = %{
      id: "cbq_#{System.unique_integer([:positive])}",
      from: build_user(),
      chat_instance: "123"
    }

    struct(CallbackQuery, Map.merge(defaults, attrs))
  end

  @doc """
  Builds an InlineQuery struct with sensible defaults; provided `attrs` override any defaults.
  
  ## Parameters
  
    - attrs: Map of fields to override the default values (for example `%{query: "hello"}`).
  
  ## Examples
  
      iex> build_inline_query(%{query: "test"})
      %InlineQuery{query: "test", id: "iq_123", from: %User{}, offset: ""}
  
  """
  @spec build_inline_query(map()) :: InlineQuery.t()
  def build_inline_query(attrs \\ %{}) do
    defaults = %{
      id: "iq_#{System.unique_integer([:positive])}",
      from: build_user(),
      query: "",
      offset: ""
    }

    struct(InlineQuery, Map.merge(defaults, attrs))
  end

  @doc """
  Constructs a Location struct with default latitude and longitude for tests.
  
  The provided `attrs` map is merged into the defaults so callers can override any field.
  
  ## Parameters
  
    - attrs: Map of fields to override in the default Location.
  
  ## Examples
  
      iex> build_location()
      %Location{latitude: 40.7128, longitude: -74.0060}
  
      iex> build_location(%{latitude: 51.5074})
      %Location{latitude: 51.5074, longitude: -74.0060}
  """
  @spec build_location(map()) :: Location.t()
  def build_location(attrs \\ %{}) do
    defaults = %{
      latitude: 40.7128,
      longitude: -74.0060
    }

    struct(Location, Map.merge(defaults, attrs))
  end
end
