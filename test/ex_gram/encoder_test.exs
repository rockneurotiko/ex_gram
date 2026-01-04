defmodule ExGram.EncoderTest do
  use ExUnit.Case, async: true

  alias ExGram.Encoder

  describe "encode/2" do
    test "encodes data to JSON" do
      data = %{key: "value", number: 42}
      assert {:ok, encoded} = Encoder.encode(data)
      assert is_binary(encoded)
      assert encoded =~ "key"
      assert encoded =~ "value"
    end

    test "encodes empty map" do
      assert {:ok, "{}"} = Encoder.encode(%{})
    end

    test "encodes list" do
      data = [1, 2, 3]
      assert {:ok, encoded} = Encoder.encode(data)
      assert encoded =~ "1"
      assert encoded =~ "2"
      assert encoded =~ "3"
    end
  end

  describe "encode!/2" do
    test "encodes data to JSON successfully" do
      data = %{key: "value"}
      result = Encoder.encode!(data)
      assert is_binary(result)
      assert result =~ "key"
    end

    test "raises on invalid data" do
      # This test depends on the JSON encoder behavior
      # Some encoders might handle this differently
      assert_raise Protocol.UndefinedError, fn ->
        Encoder.encode!({:tuple, :not_supported})
      end
    end
  end

  describe "decode/2" do
    test "decodes JSON string" do
      json = ~s({"key":"value","number":42})
      assert {:ok, decoded} = Encoder.decode(json)
      assert is_map(decoded)
      assert decoded["key"] == "value"
      assert decoded["number"] == 42
    end

    test "decodes empty JSON object" do
      assert {:ok, %{}} = Encoder.decode("{}")
    end

    test "decodes JSON array" do
      json = "[1,2,3]"
      assert {:ok, decoded} = Encoder.decode(json)
      assert is_list(decoded)
      assert decoded == [1, 2, 3]
    end

    test "returns error for invalid JSON" do
      assert {:error, _} = Encoder.decode("invalid json")
    end
  end

  describe "decode!/2" do
    test "decodes JSON string successfully" do
      json = ~s({"key":"value"})
      result = Encoder.decode!(json)
      assert is_map(result)
      assert result["key"] == "value"
    end

    test "raises on invalid JSON" do
      assert_raise Jason.DecodeError, fn ->
        Encoder.decode!("invalid json")
      end
    end
  end
end
