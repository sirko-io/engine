defmodule Sirko.Plugs.Cors do
  @moduledoc """
  Defines CORS headers to allow the client to requests the app.
  """

  import Plug.Conn

  @allowed_http_methods "get"

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> put_resp_header("access-control-allow-origin", Keyword.get(opts, :client_url))
    |> put_resp_header("access-control-allow-methods", @allowed_http_methods)
    |> put_resp_header("access-control-allow-credentials", "true")
  end
end
