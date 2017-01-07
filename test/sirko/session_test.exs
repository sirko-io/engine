defmodule Sirko.SessionTest do
  use ExUnit.Case

  doctest Sirko.Session

  import Support.Neo4jHelpers
  import Sirko.Session

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "track/3" do
    setup do
      session_key = "skey20"

      load_fixture("diverse_sessions")

      { :ok, [session_key: session_key] }
    end

    test "starts a new session with a unique key when a session key is not given" do
      assert track("/popular", nil, nil) != track("/popular", nil, nil)
    end

    test "adds a new visited page to the existing session", %{ session_key: session_key } do
      track("/details", "/list", session_key)

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, session_key) == 3
    end

    test "returns the given session key", %{ session_key: session_key } do
      assert track("/details", "/list", session_key) == session_key
    end

    test "does not create a new session relation when the session key is invalid" do
      invalid_session_key = "fake-skey"

      track("/details", "/list", invalid_session_key)

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, invalid_session_key) == 0
    end

    test "starts a new session when the session key is invalid" do
      invalid_session_key = "fake-skey"

      session_key = track("/details", "/list", invalid_session_key)

      assert session_key != nil
      assert session_key != invalid_session_key
    end
  end

  describe "expire/1" do
    setup do
      session_keys = ["skey10"]

      load_fixture("diverse_sessions")

      { :ok, [session_keys: session_keys] }
    end

    test "expires the session having the given key", %{ session_keys: session_keys } do
      expire(session_keys)

      query = """
        MATCH (:Page { start: true })-[s:SESSION * { key: {key} }]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query, List.first(session_keys)) == 2
    end

    test "tracks transitions", %{ session_keys: session_keys } do
      expire(session_keys)

      query = """
        MATCH (:Page { start: true })-[t:TRANSITION * ]->(:Page { exit: true })
        RETURN count(t) AS items_count
      """

      assert items_count(query) == 2
    end
  end

  describe "expire_all_inactive/0" do
    setup do
      load_fixture("diverse_sessions")

      :ok
    end

    test "removes short sessions" do
      expire_all_inactive()

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, "skey23") == 0
    end

    test "expires inactive sessions" do
      expire_all_inactive()

      query = """
        MATCH ()-[s:SESSION]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query) == 7
    end

    test "tracks transitions" do
      expire_all_inactive()

      query = """
        MATCH ()-[t:TRANSITION]->(:Page { exit: true })
        RETURN count(t) AS items_count
      """

      assert items_count(query) == 2
    end
  end

  defp items_count(query) do
    [%{ "items_count" => count }] = execute_query(query)

    count
  end

  defp items_count(query, session_key) do
    [%{ "items_count" => count }] = execute_query(query, %{ key: session_key })

    count
  end
end