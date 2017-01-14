defmodule Sirko.Web do
  @moduledoc """
  Accepts HTTP requests from external clients in order to track
  visited page and make prediction for the current request.
  """

  use Plug.Router
  require Logger

  import Sirko.Url, only: [ extract_path: 1 ]

  alias Sirko.Predictor

  plug Plug.Logger
  plug Plug.Static,
    at: "assets",
    from: :sirko

  plug Sirko.Plugs.Access
  plug Sirko.Plugs.Cors
  plug Sirko.Plugs.Session,
    on: "/predict"

  plug :match
  plug :dispatch

  def init(opts) do
    opts
  end

  def start_link(opts) do
    cowboy_opts = [
      port: Keyword.get(opts, :port)
    ]

    client_url = Keyword.get(opts, :client_url)

    Logger.info("Expecting requests from #{client_url}")

    Plug.Adapters.Cowboy.child_spec(:http, Sirko.Web, [], cowboy_opts)
  end

  get "/predict" do
    current_path = conn.query_params["cur"] |> extract_path
    next_path = predict(current_path)

    log_prediction(current_path, next_path)

    conn
    |> send_resp(200, next_path)
    |> halt
  end

  if Mix.env == :dev do
    # This action is only require for the dev environment. The prod environment contains
    # the js client in the priv/static folder. Hence, the Plug.Static is able to serve it.
    get "/assets/client.js" do
      {:ok, content} = File.read("node_modules/sirko-client/dist/sirko.js")

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

  defp predict(current_path) do
    Predictor.predict(current_path) || ""
  end

  defp log_prediction(current_path, "") do
    Logger.info("No prediction for #{current_path}")
  end

  defp log_prediction(current_path, next_path) do
    Logger.info("Predicted #{next_path} for #{current_path}")
  end
end
