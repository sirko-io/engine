defmodule Sirko.CleanerTest do
  use ExUnit.Case

  doctest Sirko.Cleaner

  import Support.Neo4jHelpers
  import Sirko.Cleaner

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "clean_up/0" do
    setup do
      load_fixture("diverse_sessions")
      load_fixture("transitions")

      :ok
    end

    test "excludes stale sessions from transitions" do
      transition = transition_between_paths("/list", "/popular")

      assert transition["count"] == 4

      clean_up()

      transition = transition_between_paths("/list", "/popular")

      assert transition["count"] == 1
    end

    test "removes stale sessions" do
      assert count_sessions("skey1") == 3

      clean_up()

      assert count_sessions("skey1") == 0
    end

    test "removes idle transitions" do
      query = """
        MATCH ()-[t:TRANSITION]->()
        WHERE t.count = 0
        RETURN count(t) > 0 AS exist
      """

      [%{"exist" => exist}] = execute_query(query)

      assert exist == true

      clean_up()

      [%{"exist" => exist}] = execute_query(query)

      assert exist == false
    end

    test "removes lonely pages" do
      assert page_exist?("/single") == true

      clean_up()

      assert page_exist?("/single") == false
    end
  end
end
