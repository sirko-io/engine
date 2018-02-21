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

  test "returns a list of pages" do
    res =
      conn(:post, "/")
      |> call(%{"current" => "/list"})

    expected_pages = [
      %{
        path: "/about",
        confidence: 4 / 14
      },
      %{
        path: "/details",
        confidence: 6 / 14
      }
    ]

    expected_assets = [
      "details.js",
      "app.js",
      "about.js"
    ]

    expected_body =
      Poison.encode!(%{
        pages: expected_pages,
        assets: expected_assets
      })

    assert res == expected_body
  end

  test "returns an empty list when the current page is a new one" do
    res =
      conn(:post, "/")
      |> call(%{"current" => "/reports"})

    assert res == "{\"pages\":[],\"assets\":[]}"
  end
end
