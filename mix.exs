defmodule Sirko.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sirko,
      version: "0.0.1",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :cowboy, :plug, :neo4j_sips, :rollbax],
      mod: {Sirko, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.2"},
      {:neo4j_sips, "~> 0.2"},
      {:rollbax, "~> 0.8"}
    ]
  end
end
