defmodule Sirko.Plugs.CorsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Sirko.Plugs.Cors, only: [ call: 2 ]

  test "sets CORS headers" do
    client_url = "http://test.localhost"

    conn = conn(:get, "/") |> call([client_url: client_url])

    assert get_resp_header(conn, "access-control-allow-origin") == [client_url]
    assert get_resp_header(conn, "access-control-allow-methods") == ["get"]
    assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
  end
end
