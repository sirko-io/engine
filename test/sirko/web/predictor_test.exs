defmodule Sirko.Web.PredictorTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Web.Predictor, only: [call: 2]

  setup do
    load_fixture("transitions")

    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  test "returns details of the next page" do
    res =
      conn(:post, "/")
      |> call(%{"current" => "/list"})

    expected_body =
      Poison.encode!(%{
        path: "/details",
        assets: ["http://example.org/popup.js"]
      })

    assert res == expected_body
  end

  test "returns an empty json string when the current page is a new one" do
    res =
      conn(:post, "/")
      |> call(%{"current" => "/reports"})

    assert res == "{}"
  end
end
