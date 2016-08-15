defmodule Sirko.Web do
  use Plug.Router
  require Logger

  alias Sirko.Session
  alias Sirko.Predictor

  plug Plug.Logger
  plug :match

  # TODO: a way to use options passed to the init method
  plug :put_cors_headers, Application.get_env(:sirko, :web)
  plug :dispatch

  @session_key_name "_spio_skey"

  @accept_http_methods "get"

  @moduledoc """
  Accepts HTTP requests from external clients in order to track
  visited page and make prediction for the current request.
  """

  def init(opts) do
    opts
  end

  def start_link(opts) do
    cowboy_opts = [
      port: Keyword.get(opts, :port)
    ]

    {:ok, _} = Plug.Adapters.Cowboy.http(Sirko.Web, [], cowboy_opts)
  end

  get "/predict" do
    conn = fetch_query_params(conn) |> fetch_cookies

    referral_path = conn.query_params["ref"] |> extract_path
    current_path = conn.query_params["cur"] |> extract_path

    session_key = conn.req_cookies[@session_key_name]

    respond(conn, referral_path, current_path, session_key)
    |> halt
  end

  match _ do
    conn
    |> send_resp(404, "")
    |> halt
  end

  defp respond(conn, _, nil, _) do
    conn
    |> send_resp(422, "")
  end

  defp respond(conn, nil, current_path, nil) do
    session_key = Session.start(current_path)

    conn
    |> put_resp_cookie(@session_key_name, session_key)
    |> send_resp(200, predict(current_path))
  end

  defp respond(conn, referral_path, current_path, session_key) do
    # TODO: do async
    conn = case Session.track(session_key, referral_path, current_path) do
      { :new_session, session_key } ->
        conn |> put_resp_cookie(@session_key_name, session_key)
        _ ->
          conn
    end

    conn
    |> send_resp(200, predict(current_path))
  end

  defp extract_path(nil), do: nil

  defp extract_path(url) do
    %{ path: path } = URI.parse(url)

    path
  end

  defp predict(current_path) do
    Predictor.predict(current_path) || ""
  end

  # TODO: move to a separate plug
  defp put_cors_headers(conn, opts) do
    conn
    |> put_resp_header("access-control-allow-origin", Keyword.get(opts, :client_url))
    |> put_resp_header("access-control-allow-methods", @accept_http_methods)
    |> put_resp_header("access-control-allow-credentials", "true")
  end
end
