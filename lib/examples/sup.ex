defmodule Examples.Sup do
  use Application

  def start, do: start(1, 1)

  def start(_, _) do
    import Supervisor.Spec

    children = [
      supervisor(Telex, []),
      worker(Examples.Simple, [:updates, Telex.Config.get(:telex, :token)])
    ]

    opts = [strategy: :one_for_one, name: Sup]
    Supervisor.start_link(children, opts)
  end
end
