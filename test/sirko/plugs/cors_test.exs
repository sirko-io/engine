defmodule Sirko.Plugs.CorsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Sirko.Plugs.Cors, only: [ call: 1 ]

  test "sets CORS headers" do
    conn = conn(:get, "/") |> call

    assert get_resp_header(conn, "access-control-allow-origin") == ["http://app.io"]
    assert get_resp_header(conn, "access-control-allow-methods") == ["get"]
    assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
  end
end
