defmodule BlackSea do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    opts = [
      port: Application.get_env(:blacksea, :port)
    ]

    children = [
      worker(BlackSea.Web, [opts])
    ]

    opts = [strategy: :one_for_one, name: BackSea.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
