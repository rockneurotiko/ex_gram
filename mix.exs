defmodule ExGram.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_gram,
      version: "0.5.0-rc6",
      package: package(),
      description: description(),
      source_url: "https://github.com/rockneurotiko/ex_gram",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      links: %{"GitHub" => "https://github.com/rockneurotiko/ex_gram"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:maxwell, "~> 2.2.1"},
      {:hackney, "~> 1.12.1"},
      {:dialyxir, "~> 0.5.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end
end
