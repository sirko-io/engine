defmodule Sirko.Db.TransitionTest do
  use ExUnit.Case

  doctest Sirko.Db.Transition

  import Support.Neo4jHelpers

  alias Sirko.Db, as: Db

  setup do
    on_exit fn ->
      cleanup_db
    end

    :ok
  end

  describe "track/1" do
    setup do
      session_key = "skey10"

      load_fixture("diverse_sessions")

      {:ok, [session_key: session_key]}
    end

    test "records transitions between pages", %{ session_key: session_key } do
      Db.Transition.track(session_key)

      assert transition_counts == [1, 2, 1]
    end

    test "increases counts for a transition when it exists", %{ session_key: session_key } do
      query = """
        MATCH (start:Page { start: true }),
        (list:Page { path: "/list" }),
        (popular:Page { path: "/popular" })
        CREATE (start)-[:TRANSITION { count: 2 }]->(list)
        CREATE (list)-[:TRANSITION { count: 2 }]->(popular)
      """

      execute_query(query)

      Db.Transition.track(session_key)

      assert transition_counts == [3, 4, 1]
    end

    test "does not affect transitions which does not belong to the given session", %{ session_key: session_key } do
      query = """
        MATCH (start:Page { start: true }), (exit:Page { exit: true })

        CREATE (details:Page { path: "/details" })

        CREATE (start)-[:TRANSITION { count: 5 }]->(details)
        CREATE (details)-[:TRANSITION { count: 5 }]->(exit)
      """

      execute_query(query)

      Db.Transition.track(session_key)

      query = """
        MATCH (:Page { start: true })-[transitions:TRANSITION * { count: 5 } ]->(:Page { exit: true })
        RETURN EXTRACT(transition IN transitions | transition.count) AS counts
      """

      [%{"counts" => counts}] = execute_query(query)

      assert counts == [5, 5]
    end

    defp transition_counts do
      query = """
        MATCH (:Page { start: true })-[transitions:TRANSITION *]->(:Page { exit: true })
        RETURN EXTRACT(transition IN transitions | transition.count) AS counts
      """

      [%{"counts" => counts}] = execute_query(query)

      counts
    end
  end
end
