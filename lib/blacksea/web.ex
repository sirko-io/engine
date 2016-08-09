defmodule BlackSea.Web do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug :match
  plug :dispatch

  def init(opts) do
    opts
  end

  def start_link(opts) do
    {:ok, _} = Plug.Adapters.Cowboy.http BlackSea.Web, [], opts
  end

  get "/" do
    conn
    |> send_resp(200, "ok")
    |> halt
  end

  match _ do
    conn
    |> send_resp(404, "Nothing here")
    |> halt
  end
end