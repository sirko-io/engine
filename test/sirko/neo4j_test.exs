defmodule Sirko.Neo4jTest do
  use ExUnit.Case

  alias Sirko.Neo4j

  describe "query_with_retries/4" do
    test "raises an error after exhausting all attempts" do
      # don't show errors related to an invalid query
      Logger.disable(self())

      assert_raise Neo4j.AttemptsExhaustedError, fn ->
        Neo4j.query_with_retries("MATCH (:error)")
      end

      Logger.enable(self())
    end
  end
end
