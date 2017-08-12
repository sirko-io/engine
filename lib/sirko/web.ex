defmodule Sirko.Web do
  @moduledoc """
  Accepts HTTP requests from external clients in order to track
  visited page and make prediction for the current request.
  """

  use Plug.Router

  require Logger

  alias Sirko.Web.{Session, Predictor}
  alias Plug.Adapters.Cowboy

  plug Plug.Logger
  plug Plug.Static,
    at: "assets",
    from: :sirko

  plug Sirko.Plugs.Access
  plug Sirko.Plugs.Cors

  plug :match
  plug :dispatch

  def start_link(opts) do
    cowboy_opts = [
      port: Keyword.get(opts, :port)
    ]

    client_url = Keyword.get(opts, :client_url)

    Logger.info fn -> "Expecting requests from #{client_url}" end

    Cowboy.child_spec(:http, Sirko.Web, [], cowboy_opts)
  end

  def init(opts) do
    opts
  end

  get "/predict" do
    conn = fetch_query_params(conn)

    case conn.query_params["cur"] do
      "" ->
        conn
        |> send_resp(422, "")
        |> halt
      _ ->
        conn
        |> Session.call
        |> Predictor.call
        |> halt
    end
  end

  if Mix.env == :dev do
    # This action is only required for the dev environment. The prod environment
    # contains the js client in the priv/static folder. Hence, the Plug.Static
    # is able to serve it.
    get "/assets/client.js" do
      {:ok, content} = File.read("node_modules/sirko/dist/sirko.js")

      conn
      |> put_resp_content_type("application/javascript")
      |> send_resp(200, content)
      |> halt
    end
  end

  match _ do
    conn
    |> send_resp(404, "")
    |> halt
  end
end
