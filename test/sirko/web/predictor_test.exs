defmodule Sirko.Web.PredictorTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Web.Predictor, only: [call: 2]

  setup do
    load_fixture("transitions")

    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  test "assigns details of the next page" do
    conn = conn(:post, "/")
    |> call(%{"current" => "/list"})

    expected_body = Poison.encode!(%{
      path:   "/details",
      assets: ["http://example.org/popup.js"]
    })

    assert conn.resp_body == expected_body
  end

  test "assigns an empty json string when the current page is a new one" do
    conn = conn(:post, "/")
    |> call(%{"current" => "/reports"})

    assert conn.resp_body == "{}"
  end
end
