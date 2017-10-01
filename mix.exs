defmodule Sirko.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :sirko,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger],
      mod: {Sirko, [version: @version]}
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
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.4"},
      {:bolt_sips, github: "dnesteryuk/bolt_sips", branch: "pool_of_connections"},
      {:rollbax, "~> 0.8"},
      {:poison, "~> 3.1"},
      {:distillery, "~> 1.4", require: false},
      {:conform, "~> 2.5", require: false},
      {:credo, "~> 0.8.5", only: [:dev, :test], runtime: false}
    ]
  end
end
