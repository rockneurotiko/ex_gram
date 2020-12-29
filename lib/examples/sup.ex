defmodule Examples.Sup do
  @moduledoc false

  use Application

  def start, do: start(1, 1)

  def start(_, _) do
    token = ExGram.Config.get(:ex_gram, :token)

    children = [
      ExGram,
      {Examples.Simple, [method: :polling, token: token]}
    ]

    opts = [strategy: :one_for_one, name: Examples.Sup]
    Supervisor.start_link(children, opts)
  end
end
