defmodule Mix.Tasks.Bot.New do
  @moduledoc """
  Mix task to create a basic bot module
  """

  use Mix.Task

  import Mix.Generator

  def run(_args) do
    app = Mix.Project.config()[:app]
    app_module = app |> Atom.to_string() |> Macro.camelize()

    target = "lib/#{app}/bot.ex"
    template_path = Path.expand("../../../templates/bot.ex", __DIR__)
    contents = EEx.eval_file(template_path, app_module: app_module, app: app)
    create_file(target, contents)

    IO.puts("""

    You should also add ExGram and #{app_module}.Bot as children of the application Supervisor,
    here is an example using polling:

    children = [
      ExGram,
      {#{app_module}.Bot, [method: :polling, token: token]}
    ]
    """)
  end
end
