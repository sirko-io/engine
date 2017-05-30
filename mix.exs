defmodule Sirko.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :sirko,
      version: @version,
      elixir: "~> 1.4",
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
      {:bolt_sips, "~> 0.3"},
      {:rollbax, "~> 0.8"},
      {:distillery, "~> 1.0", require: false},
      {:conform, "~> 2.1", require: false},
      {:credo, "~> 0.7.4", only: [:dev, :test], runtime: false}
    ]
  end
end
