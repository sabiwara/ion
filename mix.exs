defmodule Ion.MixProject do
  use Mix.Project

  @version "0.1.1"
  @github_url "https://github.com/sabiwara/ion"

  def project do
    [
      app: :ion,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [flags: [:missing_return, :extra_return]],
      aliases: aliases(),
      consolidate_protocols: Mix.env() != :test,

      # hex
      description: "Lightweight utility library for efficient IO data and chardata handling",
      package: package(),
      name: "Ion",
      docs: docs()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      # doc, benchs
      {:ex_doc, "~> 0.28", only: :docs, runtime: false},
      {:benchee, "~> 1.1", only: :bench, runtime: false},
      # CI
      {:dialyxir, "~> 1.0", only: :test, runtime: false},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["sabiwara"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url},
      files: ~w(lib mix.exs README.md LICENSE.md CHANGELOG.md images/logo_small.png)
    ]
  end

  defp aliases do
    [
      "test.unit": ["test --exclude property:true"],
      "test.prop": ["test --only property:true"]
    ]
  end

  def cli do
    [
      preferred_envs: [
        docs: :docs,
        "hex.publish": :docs,
        dialyzer: :test,
        "test.unit": :test,
        "test.prop": :test
      ]
    ]
  end

  defp docs do
    [
      main: "Ion",
      logo: "images/logo_small.png",
      source_ref: "v#{@version}",
      source_url: @github_url,
      homepage_url: @github_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"]
    ]
  end
end
