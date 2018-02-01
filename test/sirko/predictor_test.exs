defmodule Sirko.PredictorTest do
  use ExUnit.Case

  doctest Sirko.Predictor

  import Support.Neo4jHelpers
  import Sirko.Predictor

  setup do
    load_fixture("transitions")

    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  describe "predict/2" do
    test "predicts the details page when the confidence threshold is 20%" do
      assert predict("/list", 0.2) == %{path: "/details", assets: ["http://example.org/popup.js"]}
    end

    test "predicts nothing when the confidence threshold is 50%" do
      assert predict("/list", 0.5) == nil
    end
  end
end
