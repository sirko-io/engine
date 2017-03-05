defmodule Sirko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Sirko.Web.start_link(get_env(:sirko, :web)),
      supervisor(Sirko.Scheduler.Supervisor, [get_env(:sirko, :scheduler)])
    ]

    opts = [strategy: :one_for_one, name: Sirko.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp get_env(ns, key) do
    Application.get_env(ns, key)
  end
end
