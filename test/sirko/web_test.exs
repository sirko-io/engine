defmodule Sirko.WebTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  alias Sirko.Web

  @opts Sirko.Web.init([])

  setup do
    load_fixture("transitions")

    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "GET /predict" do
    test "assigns a session key" do
      conn = call("/list")

      assert conn.resp_cookies["_spio_skey"][:value] != nil
    end

    test "sets CORS headers" do
      conn = call("/list")

      assert get_resp_header(conn, "access-control-allow-methods") != nil
    end

    test "returns the path of a next page" do
      conn = call("/list")

      assert conn.resp_body == "/details"
    end

    test "rejects requests with the blank cur parameter" do
      conn = call(nil)

      assert conn.status == 422
    end

    test "rejects requests without the cur parameter" do
      conn = conn(:get, "/predict") |> Web.call(@opts)

      assert conn.status == 422
    end
  end

  defp call(current_path) do
    conn(:get, "/predict?cur=#{current_path}")
    |> put_req_header("referer", "http://app.io")
    |> Web.call(@opts)
  end
end
