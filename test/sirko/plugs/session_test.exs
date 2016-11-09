defmodule Sirko.Plugs.SessionTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Plugs.Session, only: [ call: 1 ]

  setup do
    on_exit fn ->
      cleanup_db
    end

    :ok
  end

  test "assigns a session key" do
    conn = conn(:get, "/predict?cur=http://app.io/list") |> call

    assert conn.resp_cookies["_spio_skey"][:value] != nil
    assert conn.resp_cookies["_spio_skey"][:max_age] == 3600
  end

  test "rejects requests without the cur parameter" do
    conn = conn(:get, "/predict") |> call

    assert conn.status == 422
  end
end
