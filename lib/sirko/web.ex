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
  plug :match

  plug Sirko.Plugs.Cors
  plug Sirko.Plugs.Session
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

    {:ok, _} = Plug.Adapters.Cowboy.http(Sirko.Web, [], cowboy_opts)
  end

  get "/predict" do
    current_path = conn.query_params["cur"] |> extract_path
    next_path = predict(current_path)

    log_prediction(current_path, next_path)

    conn
    |> send_resp(200, next_path)
    |> halt
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
