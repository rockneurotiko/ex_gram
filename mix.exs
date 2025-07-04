defmodule ExGram.Mixfile do
  use Mix.Project

  @source_url "https://github.com/rockneurotiko/ex_gram"
  @version "0.56.0"

  def project do
    [
      app: :ex_gram,
      version: @version,
      package: package(),
      description: description(),
      source_url: "https://github.com/rockneurotiko/ex_gram",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :app_tree,
        plt_add_apps: [:tesla, :mix, :eex]
      ],
      xref: [exclude: [EEx]],
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Don't need to write all applications thanks of new feature on elixir 1.4
    [extra_applications: [:logger]]
  end

  defp description do
    "Telegram Bot API low level and framework"
  end

  defp package do
    [
      maintainers: ["Miguel Garcia / Rock Neurotiko"],
      licenses: ["Beerware"],
      links: %{"GitHub" => "https://github.com/rockneurotiko/ex_gram"},
      files: ~w(lib templates mix.exs README.md)
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Tesla adapter
      {:tesla, "~> 1.14", optional: true},
      {:gun, "~> 2.0", optional: true},
      {:hackney, "~> 1.20", optional: true},
      # JSON encoders/decoders
      {:jason, ">= 1.0.0", optional: true},
      {:poison, ">= 1.0.0", optional: true},
      # Webhook adapter
      {:plug, "~> 1.14", optional: true},
      # Development
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: @version,
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Updates: ~r/ExGram\.Updates.*/,
        Adapters: ~r/ExGram\.Adapter.*/,
        DSL: ~r/ExGram\.Dsl.*/,
        Middlewares: ~r/ExGram\.Middleware.*/,
        Responses: ~r/ExGram\.Responses.*/,
        Encoder: ~r/ExGram\.Encoder.*/,
        Macros: ~r/ExGram\.Macros.*/,
        Models: ~r/ExGram\.Model.*/
      ]
    ]
  end
end
