defmodule Sirko.Config.Provider do
  @moduledoc """
  Transfers settings defined for a neo4j namespace to a bolt_sips.Bolt namespace.

  The neo4j namespace is used in the production config file to avoid confusion,
  users mightn't know the bolt_sips driver. Although, those settings are meant
  to be specified for the bolt_sips app.
  """

  use Mix.Releases.Config.Provider

  import Application, only: [get_env: 2, get_all_env: 1, put_env: 4]

  def init(_) do
    config =
      get_env(:bolt_sips, Bolt)
      |> Keyword.merge(get_all_env(:neo4j))

    put_env(:bolt_sips, Bolt, config, persistent: true)
  end
end
