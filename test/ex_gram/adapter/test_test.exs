defmodule ExGram.Adapter.TestTest do
  use ExUnit.Case, async: true

  alias ExGram.Adapter.Test, as: TestAdapter

  setup do
    TestAdapter.clean()
    :ok
  end

  describe "stub/2 - action-specific stub" do
    test "works with static data return" do
      TestAdapter.stub(:get_me, %{id: 123, is_bot: true})

      {:ok, response} = TestAdapter.request(:post, "getMe", %{}, [])

      assert response == %{id: 123, is_bot: true}
    end

    test "works with arity-1 callback receiving body" do
      TestAdapter.stub(:send_message, fn body ->
        %{message_id: 1, text: body[:text]}
      end)

      {:ok, response} = TestAdapter.request(:post, "sendMessage", %{text: "hello"}, [])

      assert response == %{message_id: 1, text: "hello"}
    end

    test "arity-1 callback can return tuple responses" do
      TestAdapter.stub(:send_message, fn body ->
        {:ok, %{message_id: 1, text: body[:text]}}
      end)

      {:ok, response} = TestAdapter.request(:post, "sendMessage", %{text: "test"}, [])

      assert response == %{message_id: 1, text: "test"}
    end

    test "stub persists across multiple calls" do
      TestAdapter.stub(:get_me, %{id: 789})

      {:ok, response1} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, response2} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, response3} = TestAdapter.request(:post, "getMe", %{}, [])

      assert response1 == %{id: 789}
      assert response2 == %{id: 789}
      assert response3 == %{id: 789}
    end
  end

  describe "stub/1 - catch-all stub" do
    test "works with arity-2 callback receiving action and body" do
      TestAdapter.stub(fn action, body ->
        %{action: action, chat_id: body[:chat_id]}
      end)

      {:ok, response} = TestAdapter.request(:post, "sendMessage", %{chat_id: 123}, [])

      assert response == %{action: :send_message, chat_id: 123}
    end

    test "handles multiple different actions" do
      TestAdapter.stub(fn action, body ->
        case action do
          :send_message ->
            {:ok, %{message_id: 1, text: body[:text]}}

          :get_me ->
            {:ok, %{id: 999, is_bot: true}}

          _ ->
            {:error, %{message: "Unknown action"}}
        end
      end)

      {:ok, msg_response} = TestAdapter.request(:post, "sendMessage", %{text: "hi"}, [])
      assert msg_response == %{message_id: 1, text: "hi"}

      {:ok, me_response} = TestAdapter.request(:post, "getMe", %{}, [])
      assert me_response == %{id: 999, is_bot: true}
    end
  end

  describe "expect/2 - action-specific expect (default n=1)" do
    test "works with static data return" do
      TestAdapter.expect(:get_me, %{id: 456, is_bot: true})

      {:ok, response} = TestAdapter.request(:post, "getMe", %{}, [])

      assert response == %{id: 456, is_bot: true}
    end

    test "expectation is consumed after one call" do
      TestAdapter.expect(:get_me, %{id: 456, is_bot: true})

      {:ok, _response} = TestAdapter.request(:post, "getMe", %{}, [])

      # Second call should fail - expectation consumed
      {:error, error} = TestAdapter.request(:post, "getMe", %{}, [])
      assert error.message =~ "No stub or expectation"
    end

    test "works with arity-1 callback receiving body" do
      TestAdapter.expect(:send_message, fn body ->
        {:ok, %{text: body[:text], uppercase: String.upcase(body[:text])}}
      end)

      {:ok, response} = TestAdapter.request(:post, "sendMessage", %{text: "test"}, [])

      assert response == %{text: "test", uppercase: "TEST"}
    end

    test "arity-1 callback expectation is consumed after one call" do
      TestAdapter.expect(:send_message, fn body ->
        {:ok, %{text: body[:text]}}
      end)

      {:ok, _} = TestAdapter.request(:post, "sendMessage", %{text: "first"}, [])

      # Second call fails
      {:error, error} = TestAdapter.request(:post, "sendMessage", %{text: "second"}, [])
      assert error.message =~ "No stub or expectation"
    end
  end

  describe "expect/3 - action-specific expect with count" do
    test "works with static data and n=2" do
      TestAdapter.expect(:get_me, 2, %{id: 789})

      {:ok, response1} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, response2} = TestAdapter.request(:post, "getMe", %{}, [])

      assert response1 == %{id: 789}
      assert response2 == %{id: 789}
    end

    test "expectation is consumed after n calls" do
      TestAdapter.expect(:get_me, 2, %{id: 789})

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])

      # Third call fails
      {:error, error} = TestAdapter.request(:post, "getMe", %{}, [])
      assert error.message =~ "No stub or expectation"
    end

    test "works with arity-1 callback and count" do
      TestAdapter.expect(:send_message, 3, fn body ->
        {:ok, %{count: body[:count]}}
      end)

      {:ok, r1} = TestAdapter.request(:post, "sendMessage", %{count: 1}, [])
      {:ok, r2} = TestAdapter.request(:post, "sendMessage", %{count: 2}, [])
      {:ok, r3} = TestAdapter.request(:post, "sendMessage", %{count: 3}, [])

      assert r1 == %{count: 1}
      assert r2 == %{count: 2}
      assert r3 == %{count: 3}

      # Fourth call fails
      {:error, _} = TestAdapter.request(:post, "sendMessage", %{count: 4}, [])
    end
  end

  describe "expect/1 - catch-all expect" do
    test "works with arity-2 callback receiving action and body" do
      TestAdapter.expect(fn action, body ->
        {:ok, %{action: action, data: body}}
      end)

      {:ok, response} = TestAdapter.request(:post, "getMe", %{test: "value"}, [])

      assert response == %{action: :get_me, data: %{test: "value"}}
    end

    test "expectation is consumed after one call" do
      TestAdapter.expect(fn action, _body ->
        {:ok, %{action: action}}
      end)

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])

      # Second call fails
      {:error, error} = TestAdapter.request(:post, "sendMessage", %{}, [])
      assert error.message =~ "No stub or expectation"
    end
  end

  describe "expect/2 overload - catch-all with count" do
    test "works with arity-2 callback and n=2" do
      TestAdapter.expect(2, fn action, _body ->
        {:ok, %{action: action}}
      end)

      {:ok, r1} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, r2} = TestAdapter.request(:post, "sendMessage", %{}, [])

      assert r1 == %{action: :get_me}
      assert r2 == %{action: :send_message}
    end

    test "expectation is consumed after n calls" do
      TestAdapter.expect(2, fn action, _body ->
        {:ok, %{action: action}}
      end)

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])
      {:ok, _} = TestAdapter.request(:post, "sendMessage", %{}, [])

      # Third call fails
      {:error, error} = TestAdapter.request(:post, "getMe", %{}, [])
      assert error.message =~ "No stub or expectation"
    end

    test "works with larger counts" do
      TestAdapter.expect(5, fn action, _body ->
        {:ok, %{action: action}}
      end)

      for _i <- 1..5 do
        {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])
      end

      # Sixth call fails
      {:error, _} = TestAdapter.request(:post, "getMe", %{}, [])
    end
  end

  describe "verify!/0 - verification behavior" do
    test "verify! fails when expectation not called" do
      TestAdapter.expect(:get_me, %{id: 123})

      # Do NOT call request
      assert_raise RuntimeError, ~r/Path-specific expectations not fulfilled/, fn ->
        TestAdapter.verify!()
      end
    end

    test "verify! fails when unexpected call made (no stub or expect)" do
      # Make a call without any stub or expect
      TestAdapter.request(:post, "getMe", %{}, [])

      assert_raise RuntimeError, ~r/Unexpected API calls with no stub or expectation/, fn ->
        TestAdapter.verify!()
      end
    end

    test "verify! passes when all expectations met" do
      TestAdapter.expect(:get_me, %{id: 123})

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])

      # Should not raise
      assert :ok = TestAdapter.verify!()
    end

    test "verify! passes with stubs (stubs don't require calls)" do
      TestAdapter.stub(:get_me, %{id: 123})

      # Do NOT call request - stubs don't need to be consumed
      assert :ok = TestAdapter.verify!()
    end

    test "verify! passes when stub is actually used" do
      TestAdapter.stub(:get_me, %{id: 123})

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])

      assert :ok = TestAdapter.verify!()
    end

    test "verify! fails when catch-all expectation not called" do
      TestAdapter.expect(fn _action, _body ->
        {:ok, %{}}
      end)

      # Do NOT call request
      assert_raise RuntimeError, ~r/Catch-all expectations not fulfilled/, fn ->
        TestAdapter.verify!()
      end
    end

    test "verify! passes when catch-all expectation is met" do
      TestAdapter.expect(fn _action, _body ->
        {:ok, %{}}
      end)

      {:ok, _} = TestAdapter.request(:post, "getMe", %{}, [])

      assert :ok = TestAdapter.verify!()
    end
  end
end
