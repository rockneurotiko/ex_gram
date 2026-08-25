defmodule ExGram.Mixfile do
  use Mix.Project

  @source_url "https://github.com/rockneurotiko/ex_gram"
  @version "0.70.0"

  def project do
    [
      app: :ex_gram,
      version: @version,
      package: package(),
      description: description(),
      source_url: "https://github.com/rockneurotiko/ex_gram",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      elixirc_options: [no_warn_undefined: [EEx]],
      hex: [ignore_advisories: ["GHSA-w4f7-4cxr-rv3c", "EEF-CVE-2026-43969"]],
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

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:iex, :mix, :eex]
    ]
  end

  defp description do
    "Telegram Bot API low level and framework"
  end

  defp package do
    [
      maintainers: ["Miguel Garcia / Rock Neurotiko"],
      licenses: ["Beerware"],
      links: %{"GitHub" => "https://github.com/rockneurotiko/ex_gram"},
      files: ~w(lib guides templates mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Tesla adapter
      {:tesla, "~> 1.16", optional: true},
      {:gun, "~> 2.0", optional: true},
      {:hackney, "~> 1.20 or ~> 4.0.2", optional: true},
      {:req, "~> 0.6.1 or ~> 0.7", optional: true},
      # JSON encoders/decoders
      {:jason, ">= 1.0.0", optional: true},
      {:poison, ">= 1.0.0", optional: true},
      # Webhook adapter
      {:plug, "~> 1.14", optional: true},
      # For Markdown to MessageEntity convert
      {:mdex, "~> 0.11", optional: true},
      # Telemetry
      {:telemetry, "~> 0.4.3 or ~> 1.0"},
      # For opentelemetry
      {:opentelemetry_api, "~> 1.2", optional: true},
      # Test adapter uses NimbleOwnership for per-process isolation
      {:nimble_ownership, "~> 1.0"},
      # Development
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false, warn_if_outdated: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false, warn_if_outdated: true},
      {:styler, "~> 1.12", only: [:dev, :test], runtime: false, warn_if_outdated: true},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: @version,
      source_url: @source_url,
      extra_section: "GUIDES",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: [
        DSL: ~r/ExGram\.Dsl.*/,
        Middlewares: ~r/ExGram\.Middleware.*/,
        Responses: ~r/ExGram\.Responses.*/,
        Test: [~r/ExGram\.Test/, ~r/ExGram\..*\.Test/],
        Updates: ~r/ExGram\.Updates.*/,
        Adapters: ~r/ExGram\.Adapter.*/,
        Encoder: ~r/ExGram\.Encoder.*/,
        Macros: ~r/ExGram\.Macros.*/,
        Models: ~r/ExGram\.Model.*/
      ]
    ]
  end

  @guides "guides" |> File.ls!() |> Enum.filter(&String.ends_with?(&1, ".md")) |> Enum.map(&"guides/#{&1}")

  defp extras do
    [
      "README.md",
      "CHANGELOG.md",
      "LICENSE"
    ] ++ @guides
  end

  defp groups_for_extras do
    [
      Cheatsheet: "guides/cheatsheet.md",
      Basic: ~r/guides\/(installation|getting-started|handling-updates|commands|sending-messages)\.md/,
      Intermediate: ~r/guides\/(router|fsm|polling-and-webhooks|message-entities|middlewares|low-level-api)\.md/,
      Observability: ~r/guides\/(telemetry|opentelemetry)\.md/,
      Advanced: ~r/guides\/(multiple-bots|flyio|bot-init-hooks)\.md/,
      Testing: "guides/testing.md",
      "Other Guides": ~r/guides\/.*/
    ]
  end
end
