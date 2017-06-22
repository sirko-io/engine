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

  describe "track/3 the reffer is not given" do
    test "returns nil" do
       assert track("/popular", nil, nil) == nil
    end
  end

  describe "track/3 the session key is not given" do
    test "starts a new session with a unique key" do
      assert track("/popular", "/", nil) != track("/popular", "/", nil)
    end

    test "adds a new visited page to a newly started session" do
      session_key = track("/popular", "/", nil)

      assert count_sessions(session_key) == 1
    end
  end

  describe "track/3 the session key is given" do
    setup do
      session_key = "skey20"

      load_fixture("diverse_sessions")

      {:ok, [session_key: session_key]}
    end

    test "adds a new visited page to the existing session", %{session_key: session_key} do
      track("/details", "/list", session_key)

      assert count_sessions(session_key) == 3
    end

    test "returns the given session key", %{session_key: session_key} do
      assert track("/details", "/list", session_key) == session_key
    end

    test "does not create a new session relation when the session key is invalid" do
      invalid_session_key = "fake-skey"

      track("/details", "/list", invalid_session_key)

      assert count_sessions(invalid_session_key) == 0
    end

    test "starts a new session when the session key is expired" do
      expired_session_key = "skey10"

      session_key = track("/details", "/list", expired_session_key)

      assert session_key != nil
      assert session_key != expired_session_key
    end
  end

  describe "expire/1" do
    setup do
      session_keys = ["skey20"]

      load_fixture("diverse_sessions")

      {:ok, [session_keys: session_keys]}
    end

    test "expires the session having the given key", %{session_keys: session_keys} do
      expire(session_keys)

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query, List.first(session_keys)) == 1
    end

    test "tracks transitions", %{session_keys: session_keys} do
      expire(session_keys)

      query = """
        MATCH ()-[t:TRANSITION]->(:Page { exit: true })
        RETURN count(t) AS items_count
      """

      assert items_count(query) == 1
    end
  end

  describe "expire_all_inactive/1" do
    setup do
      load_fixture("diverse_sessions")

      {:ok, [inactive_session_in: 3600 * 1000]}
    end

    test "expires inactive sessions", %{inactive_session_in: inactive_session_in} do
      expire_all_inactive(inactive_session_in)

      query = """
        MATCH ()-[s:SESSION]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query) == 8
    end

    test "tracks transitions", %{inactive_session_in: inactive_session_in} do
      expire_all_inactive(inactive_session_in)

      query = """
        MATCH ()-[t:TRANSITION]->(:Page { exit: true })
        RETURN count(t) AS items_count
      """

      assert items_count(query) == 3
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
