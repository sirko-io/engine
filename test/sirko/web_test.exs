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

  describe "POST /predict" do
    test "assigns a session key" do
      conn = call("/list")

      assert conn.resp_cookies["_spio_skey"][:value] != nil
    end

    test "sets CORS headers" do
      conn = call("/list")

      assert get_resp_header(conn, "access-control-allow-methods") != nil
    end

    test "returns details of the next page" do
      conn = call("/list")

      assert conn.resp_body == Poison.encode!(
        %{path: "/details", assets: ["http://example.org/popup.js"]}
      )
    end

    test "rejects requests with the blank current parameter" do
      conn = call(nil)

      assert conn.status == 422
    end

    test "rejects requests without the current parameter" do
      conn = conn(:post, "/predict") |> Web.call(@opts)

      assert conn.status == 422
    end
  end

  defp call(current_path) do
    body = Poison.encode!(%{current: current_path, referrer: "/"})

    conn(:post, "/predict", body)
    |> put_req_header("referer", "http://app.io")
    |> put_req_header("content-type", "application/json")
    |> Web.call(@opts)
  end
end
