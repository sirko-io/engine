defmodule Sirko.Web.PredictorTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Web.Predictor, only: [ call: 1 ]

  setup do
    load_fixture("transitions")

    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  test "assigns the path of a next page" do
    conn = conn(:get, "/predict?cur=/list")
    |> fetch_query_params
    |> call

    assert conn.resp_body == "/details"
  end

  test "assigns an empty string when the current page is a new one" do
    conn = conn(:get, "/predict?cur=/reports")
    |> fetch_query_params
    |> call

    assert conn.resp_body == ""
  end
end
