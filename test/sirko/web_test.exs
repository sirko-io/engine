defmodule Sirko.WebTest do
  use ExUnit.Case
  use Plug.Test

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
    test "assigns a session key" do
      conn = conn(:get, "/predict?cur=http://app.io/list") |> call

      assert conn.resp_cookies["_spio_skey"][:value] != nil
    end

    test "sets CORS headers" do
      conn = conn(:get, "/predict?cur=http://app.io/list") |> call

      assert get_resp_header(conn, "access-control-allow-methods") != nil
    end

    test "returns the path of a next page" do
      conn = conn(:get, "/predict?cur=http://app.io/list") |> call

      assert conn.resp_body == "/details"
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
