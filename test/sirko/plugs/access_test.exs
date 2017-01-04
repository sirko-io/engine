defmodule Sirko.Plugs.AccessTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Sirko.Plugs.Access, only: [ call: 1 ]

  test "passes when the request comes from the known client" do
    conn = conn(:get, "/")
    |> put_req_header("referer", "http://app.io")
    |> call

    assert conn.status == nil
  end

  test "rejects when the request comes from a unknown client" do
    conn = conn(:get, "/")
    |> put_req_header("referer", "http://example.org")
    |> call

    assert conn.status == 422
  end

  test "rejects when the referer isn't supplied" do
    conn = conn(:get, "/") |> call

    assert conn.status == 422
  end
end