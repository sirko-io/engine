defmodule Sirko.SessionTest do
  use ExUnit.Case

  doctest Sirko.Session

  import Support.Neo4jHelpers
  import Sirko.Session

  alias Sirko.Entry

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  describe "track/3 the referrer is not given" do
    test "returns nil" do
      assert track(Entry.new(current_path: "/popular", referrer_path: nil), nil) == nil
    end
  end

  describe "track/3 the session key is not given" do
    setup do
      entry = Entry.new(current_path: "/popular", referrer_path: "/")

      {:ok, [entry: entry]}
    end

    test "starts a new session with a unique key", %{entry: entry} do
      refute track(entry, nil) == track(entry, nil)
    end

    test "adds a new visited page to a newly started session", %{entry: entry} do
      session_key = track(entry, nil)

      assert count_sessions(session_key) == 1
    end
  end

  describe "track/3 the session key is given" do
    setup do
      session_key = "skey20"
      entry = Entry.new(current_path: "/details", referrer_path: "/list")

      load_fixture("diverse_sessions")

      {:ok, [session_key: session_key, entry: entry]}
    end

    test "adds a new visited page to the existing session", info do
      %{session_key: session_key, entry: entry} = info

      track(entry, session_key)

      assert count_sessions(session_key) == 3
    end

    test "returns the given session key", info do
      %{session_key: session_key, entry: entry} = info

      assert track(entry, session_key) == session_key
    end

    test "does not create a new session relation when the session key is invalid", info do
      %{entry: entry} = info

      invalid_session_key = "fake-skey"

      track(entry, invalid_session_key)

      assert count_sessions(invalid_session_key) == 0
    end

    test "starts a new session when the session key is expired", info do
      %{entry: entry} = info

      expired_session_key = "skey10"

      session_key = track(entry, expired_session_key)

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
    [%{"items_count" => count}] = execute_query(query)

    count
  end

  defp items_count(query, session_key) do
    [%{"items_count" => count}] = execute_query(query, %{key: session_key})

    count
  end
end
