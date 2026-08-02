defmodule ExGram.MixfileTest do
  use ExUnit.Case, async: true

  test "supports secure req release lines" do
    {:req, requirement, opts} =
      Mix.Project.config()[:deps]
      |> Enum.find(fn
        {:req, _requirement, _opts} -> true
        _ -> false
      end)

    assert requirement == "~> 0.5.10 or ~> 0.6 or ~> 1.0"
    assert opts[:optional] == true
  end
end
