defmodule Sirko.Web.SessionTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Web.Session, only: [ call: 1 ]

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  test "does not assign a session key when the transition hasn't happened yet" do
    conn = conn(:get, "/predict?cur=/list")
    |> fetch_query_params
    |> call

    assert conn.resp_cookies["_spio_skey"] == nil
  end

  test "assigns a session key when the transition has happened" do
    conn = conn(:get, "/predict?cur=/list&ref=/home")
    |> fetch_query_params
    |> call

    assert conn.resp_cookies["_spio_skey"][:value] != nil
    assert conn.resp_cookies["_spio_skey"][:max_age] == 3600
  end
end
