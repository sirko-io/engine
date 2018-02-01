defmodule Sirko.CleanerTest do
  use ExUnit.Case

  doctest Sirko.Cleaner

  import Support.Neo4jHelpers
  import Sirko.Cleaner

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  describe "clean_up/1" do
    setup do
      load_fixture("diverse_sessions")
      load_fixture("transitions")

      {:ok, [stale_session_in: 3600 * 1000 * 24 * 7]}
    end

    test "excludes stale sessions from transitions", %{stale_session_in: stale_session_in} do
      transition = transition_between_paths("/list", "/popular")

      assert transition.properties["count"] == 4

      clean_up(stale_session_in)

      transition = transition_between_paths("/list", "/popular")

      assert transition.properties["count"] == 1
    end

    test "removes stale sessions", %{stale_session_in: stale_session_in} do
      assert count_sessions("skey1") == 3

      clean_up(stale_session_in)

      assert count_sessions("skey1") == 0
    end

    test "removes idle transitions", %{stale_session_in: stale_session_in} do
      query = """
        MATCH ()-[t:TRANSITION]->()
        WHERE t.count = 0
        RETURN count(t) > 0 AS exist
      """

      [%{"exist" => exist}] = execute_query(query)

      assert exist == true

      clean_up(stale_session_in)

      [%{"exist" => exist}] = execute_query(query)

      assert exist == false
    end

    test "removes lonely pages", %{stale_session_in: stale_session_in} do
      assert page_exist?("/single") == true

      clean_up(stale_session_in)

      assert page_exist?("/single") == false
    end
  end
end
