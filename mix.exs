defmodule ExGram.Mixfile do
  use Mix.Project

  @version "0.50.0"

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
        plt_add_apps: [:tesla, :maxwell, :mix, :eex]
      ],
      xref: [exclude: [EEx]],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
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
      {:tesla, "~> 1.2", optional: true},
      {:gun, "~> 1.3", optional: true},
      # Maxwell or Tesla
      {:hackney, "~> 1.20", optional: true},
      # Maxwell adapter
      {:maxwell, "~> 2.3.1", optional: true},
      # JSON encoders/decoders
      {:jason, ">= 1.0.0", optional: true},
      {:poison, ">= 1.0.0", optional: true},
      # Webhook adapter
      {:plug, "~> 1.14", optional: true},
      # Development
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev},
      {:inch_ex, "~> 0.5.0", only: :docs},
      {:styler, "~> 0.10", only: :dev, runtime: false}
    ]
  end
end
