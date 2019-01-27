defmodule Sirko.Mixfile do
  use Mix.Project

  @version "0.5.0"

  def project do
    [
      app: :sirko,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]]
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
      {:cowboy, "~> 2.6"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:bolt_sips, github: "florinpatrascu/bolt_sips"},
      {:rollbax, "~> 0.10"},
      {:poison, "~> 4.0"},
      {:oauth2, "~> 0.9", require: false},
      {:distillery, "~> 2.0", require: false},
      {:toml, github: "bitwalker/toml-elixir"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:benchee, "~> 0.13", only: [:dev]}
    ]
  end
end
