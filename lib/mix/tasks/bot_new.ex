defmodule Mix.Tasks.Bot.New do
  use Mix.Task

  import Mix.Generator

  def run(_args) do
    app = Mix.Project.config()[:app]
    app_string = app |> Atom.to_string()

    app_module =
      app_string |> String.split("_") |> Enum.map(&String.capitalize/1) |> Enum.join("")

    target = "lib/#{app}/bot.ex"
    contents = EEx.eval_file("templates/bot.ex", app_module: app_module, app: app)
    create_file(target, contents)
  end
end
