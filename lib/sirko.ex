defmodule Sirko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # This line is required to fix an error which appears after executing:
    #
    #     :erlang.binary_to_existing_atom("bolt", :utf8)
    #
    # Probably, Neo4j Sips or its dependency tries to access the existing bolt prior to its creation.
    # This issue was found in the CI, locally, it wasn't reproduced.
    _bolt = :bolt

    children = [
      Sirko.Web.start_link(get_env(:sirko, :web)),
      worker(Sirko.Scheduler.Server, [get_env(:sirko, :scheduler)]),
      supervisor(Neo4j.Sips,         [get_env(:neo4j_sips, Neo4j)])
    ]

    opts = [strategy: :one_for_one, name: Sirko.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp get_env(ns, key) do
    Application.get_env(ns, key)
  end
end
