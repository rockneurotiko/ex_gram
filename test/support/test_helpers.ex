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

  def unique_name(context, prefix) do
    base = context.test |> Atom.to_string() |> String.replace(~r/[^a-z0-9]/i, "_")
    String.to_atom("#{prefix}_#{base}_#{System.unique_integer([:positive])}")
  end

  def unique_bot_name(context) do
    unique_name(context, "bot_test")
  end

  @doc """
  Build a User struct with default test values that can be overridden.
  """
  def build_user(attrs \\ %{}) do
    defaults = %{
      id: System.unique_integer([:positive]),
      is_bot: false,
      first_name: "Test"
    }

    struct(User, Map.merge(defaults, attrs))
  end

  @doc """
  Build a Chat struct with default test values that can be overridden.
  """
  def build_chat(attrs \\ %{}) do
    defaults = %{
      id: System.unique_integer([:positive]),
      type: "private"
    }

    struct(Chat, Map.merge(defaults, attrs))
  end

  @doc """
  Build a Message struct with default test values that can be overridden.
  """
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
  Build an Update struct with default test values that can be overridden.
  """
  def build_update(attrs \\ %{}) do
    defaults = %{
      update_id: System.unique_integer([:positive])
    }

    struct(Update, Map.merge(defaults, attrs))
  end

  @doc """
  Build a CallbackQuery struct with default test values that can be overridden.
  """
  def build_callback_query(attrs \\ %{}) do
    defaults = %{
      id: "cbq_#{System.unique_integer([:positive])}",
      from: build_user(),
      chat_instance: "123"
    }

    struct(CallbackQuery, Map.merge(defaults, attrs))
  end

  @doc """
  Build an InlineQuery struct with default test values that can be overridden.
  """
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
  Build a Location struct with default test values that can be overridden.
  """
  def build_location(attrs \\ %{}) do
    defaults = %{
      latitude: 40.7128,
      longitude: -74.0060
    }

    struct(Location, Map.merge(defaults, attrs))
  end
end
