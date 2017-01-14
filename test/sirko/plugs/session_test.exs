defmodule Sirko.Plugs.SessionTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Plugs.Session, only: [ call: 2 ]

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  test "assigns a session key" do
    conn = conn(:get, "/predict?cur=http://app.io/list") |> call(on: "/predict")

    assert conn.resp_cookies["_spio_skey"][:value] != nil
    assert conn.resp_cookies["_spio_skey"][:max_age] == 3600
  end

  test "rejects requests without the cur parameter" do
    conn = conn(:get, "/predict") |> call(on: "/predict")

    assert conn.status == 422
  end

  test "doesn't do anything when the given path doesn't match the expected one" do
    conn = conn(:get, "/predict") |> call(on: "/expectation")

    assert conn.status == nil
  end
end
