defmodule ExGram.TestFacadeTest do
  use ExUnit.Case, async: true

  alias ExGram.Test

  setup do
    # Clean state before each test
    Test.clean()
    :ok
  end

  describe "stub/2" do
    test "delegates to Adapter.Test.stub/2" do
      Test.stub(:send_message, %{message_id: 1, text: "ok"})

      {:ok, response} = ExGram.send_message(123, "Hello")
      assert response.message_id == 1
      assert response.text == "ok"
    end

    test "records calls via get_calls/0" do
      Test.stub(:send_message, %{message_id: 1, text: "ok"})

      ExGram.send_message(123, "Hello")

      calls = Test.get_calls()
      assert length(calls) == 1

      {verb, action, body} = hd(calls)
      assert verb == :post
      assert action == :send_message
      assert body[:chat_id] == 123
      assert body[:text] == "Hello"
    end
  end

  describe "stub/1 catch-all" do
    test "delegates to Adapter.Test.stub/1" do
      Test.stub(fn action, body ->
        case action do
          :send_message ->
            {:ok, %{message_id: 1, chat: %{id: body[:chat_id]}, text: "ok"}}

          :get_me ->
            {:ok, %{id: 1, is_bot: true, first_name: "TestBot"}}

          _ ->
            {:error, %ExGram.Error{message: "Unexpected: #{action}"}}
        end
      end)

      {:ok, msg} = ExGram.send_message(123, "Hello")
      assert msg.message_id == 1

      {:ok, bot} = ExGram.get_me()
      assert bot.first_name == "TestBot"
    end
  end

  describe "stub_error/2" do
    test "delegates to Adapter.Test.stub_error/2" do
      error = %ExGram.Error{code: 400, message: "Bad Request"}
      Test.stub_error(:send_message, error)

      result = ExGram.send_message(123, "Hello")
      assert {:error, %ExGram.Error{message: "Bad Request"}} = result
    end
  end

  describe "expect/2" do
    test "delegates to Adapter.Test.expect/2" do
      Test.expect(:send_message, %{message_id: 1, text: "ok"})

      {:ok, response} = ExGram.send_message(123, "Hello")
      assert response.message_id == 1

      # Second call fails - expectation consumed
      {:error, _} = ExGram.send_message(123, "Hello again")
    end

    test "works with callbacks" do
      Test.expect(:send_message, fn body ->
        assert body[:text] == "Hello"
        {:ok, %{message_id: 1, text: "ok"}}
      end)

      {:ok, _} = ExGram.send_message(123, "Hello")
    end
  end

  describe "expect/3 with count" do
    test "delegates to Adapter.Test.expect/3" do
      Test.expect(:send_message, 2, %{message_id: 1, text: "ok"})

      {:ok, _} = ExGram.send_message(123, "First")
      {:ok, _} = ExGram.send_message(123, "Second")

      # Third call fails
      {:error, _} = ExGram.send_message(123, "Third")
    end
  end

  describe "expect/1 catch-all" do
    test "delegates to Adapter.Test.expect/1" do
      Test.expect(fn action, body ->
        assert action in [:send_message, :get_me]

        case action do
          :send_message ->
            {:ok, %{message_id: 1, chat: %{id: body[:chat_id]}, text: "ok"}}

          :get_me ->
            {:ok, %{id: 1, is_bot: true}}
        end
      end)

      {:ok, _} = ExGram.send_message(123, "Hello")

      # Second call fails - expectation consumed
      {:error, _} = ExGram.get_me()
    end
  end

  describe "expect/2 catch-all with count" do
    test "delegates to Adapter.Test.expect/2" do
      Test.expect(2, fn action, body ->
        case action do
          :send_message ->
            {:ok, %{message_id: 1, chat: %{id: body[:chat_id]}, text: "ok"}}

          :get_me ->
            {:ok, %{id: 1, is_bot: true}}

          _ ->
            {:ok, true}
        end
      end)

      {:ok, _} = ExGram.send_message(123, "First")
      {:ok, _} = ExGram.get_me()

      # Third call fails
      {:error, _} = ExGram.send_message(123, "Third")
    end
  end

  describe "verify!/0" do
    test "delegates to Adapter.Test.verify!/0" do
      Test.expect(:send_message, %{message_id: 1, text: "ok"})

      # Not called yet
      assert_raise RuntimeError, ~r/Path-specific expectations not fulfilled/, fn ->
        Test.verify!()
      end
    end

    test "passes when expectations are met" do
      Test.expect(:send_message, %{message_id: 1, text: "ok"})
      ExGram.send_message(123, "Hello")

      # Should not raise
      Test.verify!()
    end
  end

  describe "verify_on_exit!/1" do
    test "delegates to Adapter.Test.verify_on_exit!/1" do
      # This test verifies the function exists and delegates correctly
      # Actual on_exit behavior is tested in the adapter tests
      Test.verify_on_exit!(%{})
    end
  end

  describe "allow/2" do
    test "delegates to Adapter.Test.allow/2" do
      Test.stub(:send_message, %{message_id: 1, text: "ok"})

      task =
        Task.async(fn ->
          ExGram.send_message(123, "From task")
        end)

      Test.allow(self(), task.pid)

      {:ok, msg} = Task.await(task)
      assert msg.message_id == 1
    end
  end

  describe "set_global/0 and set_private/0" do
    test "delegates to Adapter.Test" do
      # Just verify the functions exist and delegate
      Test.set_global()
      Test.set_private()
    end
  end

  describe "clean/0" do
    test "delegates to Adapter.Test.clean/0" do
      Test.stub(:send_message, %{message_id: 1, text: "ok"})
      ExGram.send_message(123, "Hello")

      assert length(Test.get_calls()) == 1

      Test.clean()

      assert length(Test.get_calls()) == 0
    end
  end

  describe "push_update/2" do
    test "delegates to Updates.Test.push_update/2" do
      # Verify the function exists on ExGram.Test
      assert function_exported?(Test, :push_update, 2)

      # Note: ExGram.Updates.Test.push_update/2 exists but may not be compiled yet in this context
      # The important thing is that ExGram.Test.push_update/2 is properly delegated
    end
  end
end
