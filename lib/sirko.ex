defmodule Sirko do
  @moduledoc """
  Implements callbacks required by the Application behavior (https://hexdocs.pm/elixir/Application.html)
  to start top-level processes.
  """

  use Application

  require Logger

  import Application, only: [get_env: 2]

  @issues_url "https://github.com/sirko-io/engine/issues"

  @doc "Callback for Application.start/2"
  def start(_type, args) do
    print_help_info(Keyword.get(args, :version))

    children = [
      {Bolt.Sips, get_env(:bolt_sips, Bolt)},
      Sirko.DbIndexes,
      {Sirko.Web, get_env(:sirko, :web)},
      {Sirko.Scheduler.Supervisor, get_env(:sirko, :scheduler)}
    ]

    opts = [strategy: :one_for_one, name: Sirko.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp print_help_info(version) do
    Logger.info(fn ->
      "The current version is #{version}. " <>
        "If you have questions/issues, please, report them #{@issues_url}"
    end)
  end
end
