defmodule Sirko.WebTest do
  use ExUnit.Case
  use Plug.Test

  doctest Sirko.Web

  import Support.Neo4jHelpers

  alias Sirko.Web

  @opts Sirko.Web.init([])

  setup do
    load_fixture("transitions")

    on_exit fn ->
      cleanup_db
    end

    :ok
  end

  describe "GET /predict" do
    test "assigns a unique session key when it is a first visit" do
      conn = conn(:get, "/predict?cur=http://app.io/list") |> call

      assert conn.resp_cookies["_spio_skey"][:value] != nil
      assert conn.resp_body == "/details"
    end

    test "setups required CORS headers" do
      conn = conn(:get, "/predict?cur=http://app.io/list") |> call

      assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.localhost:3000"]
      assert get_resp_header(conn, "access-control-allow-methods") == ["get"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end

    test "rejects requests without the cur parameter" do
      conn = conn(:get, "/predict") |> call

      assert conn.status == 422
    end

    test "does not assign a new session key when it is a returned user" do
      session_key = "skey30"

      load_fixture("diverse_sessions")

      conn = conn(:get, "/predict?cur=http://app.io/details&ref=http://app.io/list")
      |> put_req_cookie("_spio_skey", session_key)
      |> call

      assert conn.resp_cookies["_spio_skey"] == nil
      assert conn.resp_body == "/popular"
    end

    test "assigns a new session key when the given session key is invalid" do
      conn = conn(:get, "/predict?cur=http://app.io/details&ref=http://app.io/list")
      |> put_req_cookie("_spio_skey", "invalid-session-key")
      |> call

      assert conn.resp_cookies["_spio_skey"][:value] != nil
      assert conn.resp_body == "/popular"
    end

    test "responds with an empty body when the current page is new" do
      conn = conn(:get, "/predict?cur=http://app.io/reports") |> call

      assert conn.resp_body == ""
    end
  end

  defp call(conn) do
    Web.call(conn, @opts)
  end
end
