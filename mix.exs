defmodule Sirko.Mixfile do
  use Mix.Project

  @version "0.4.1"

  def project do
    [
      app: :sirko,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.5"},
      {:bolt_sips, github: "florinpatrascu/bolt_sips"},
      {:rollbax, "~> 0.9"},
      {:poison, "~> 3.1"},
      {:distillery, "~> 2.0", require: false},
      {:toml, github: "bitwalker/toml-elixir"},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end
end
