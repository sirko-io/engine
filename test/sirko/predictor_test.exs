defmodule Sirko.PredictorTest do
  use ExUnit.Case, async: true

  doctest Sirko.Predictor

  import Support.Neo4jHelpers

  import Sirko.Predictor, only: [ predict: 1 ]

  setup do
    load_fixture("transitions")

    on_exit fn ->
      cleanup_db
    end

    :ok
  end

  test "predicts a next page when the user is on the list page" do
    assert predict("/list") == "/details"
  end

  test "returns nil when the current page is unknown" do
    assert predict("/settings") == nil
  end
end
