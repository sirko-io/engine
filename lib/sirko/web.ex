defmodule Sirko.Web do
  @moduledoc """
  Accepts HTTP requests from external clients in order to track
  visited page and make prediction for the current request.
  """

  use Plug.Router

  require Logger

  alias Sirko.Web.{Session, Predictor}
  alias Plug.Cowboy

  plug(Plug.Logger)
  plug(Sirko.Plugs.Cors)

  plug(
    Plug.Static,
    at: "assets",
    from: :sirko
  )

  plug(Sirko.Plugs.Access)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  @spec child_spec(opts :: Keyword.t()) :: any
  def child_spec(opts) do
    cowboy_opts = [
      scheme: :http,
      plug: __MODULE__,
      options: [
        port: Keyword.get(opts, :port)
      ]
    ]

    client_url = Keyword.get(opts, :client_url)

    Logger.info(fn -> "Expecting requests from #{client_url}" end)

    Cowboy.child_spec(cowboy_opts)
  end

  def init(opts), do: opts

  options "/predict" do
    conn
    |> send_resp(200, "")
  end

  post "/predict" do
    params = conn.params

    case params["current"] do
      nil ->
        conn
        |> send_resp(422, "")
        |> halt

      _ ->
        tracking = track(conn, params)
        predicting = predict(conn, params)

        conn
        |> build_resp(tracking, predicting)
        |> halt
    end
  end

  if Mix.env() == :dev do
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

  defp track(conn, params) do
    Task.async(Session, :call, [conn, params])
  end

  defp predict(conn, params) do
    Task.async(Predictor, :call, [conn, params])
  end

  defp build_resp(conn, tracking, predicting) do
    timeout = 30_000

    conn
    |> put_session_key(Task.await(tracking, timeout))
    |> put_resp_body(Task.await(predicting, timeout))
  end

  defp put_resp_body(conn, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  defp put_session_key(conn, nil), do: conn

  defp put_session_key(conn, cookie) do
    {name, val, opts} = cookie

    conn
    |> put_resp_cookie(name, val, opts)
  end
end
