defmodule Sirko.SessionTest do
  use ExUnit.Case

  doctest Sirko.Session

  import Support.Neo4jHelpers
  import Sirko.Session

  setup do
    on_exit fn ->
      cleanup_db
    end

    :ok
  end

  describe "start/1" do
    test "creates a new session with a unique key" do
      assert start("/popular") != start("/popular")
    end
  end

  describe "track/3" do
    setup do
      session_key = "skey20"

      load_fixture("diverse_sessions")

      { :ok, [session_key: session_key] }
    end

    test "adds a new visited page to the existing session", %{ session_key: session_key } do
      track(session_key, "/list", "/details")

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, session_key) == 3
    end

    test "does not create a new session relation when the session key is invalid" do
      session_key = "fake-skey"

      track(session_key, "/list", "/details")

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, session_key) == 0
    end

    test "starts a new session when the session key is invalid" do
      fake_session_key = "fake-skey"

      { :new_session, session_key } = track(fake_session_key, "/list", "/details")

      assert session_key != nil
      assert session_key != fake_session_key
    end

    # TODO: think more about this case
    @tag :skip
    test "does not create a new session relation when the session does not include the given referral", %{ session_key: session_key } do
      track(session_key, "/details", "/popular")

      query = """
        MATCH ()-[s:SESSION { key: {key} }]->()
        RETURN count(s) AS items_count
      """

      assert items_count(query, session_key) == 1
    end
  end

  describe "expire/1" do
    setup do
      session_key = "skey10"

      load_fixture("diverse_sessions")

      { :ok, [session_key: session_key] }
    end

    test "expires the session having the given key", %{ session_key: session_key } do
      expire(session_key)

      query = """
        MATCH (:Page { start: true })-[s:SESSION * { key: {key} }]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query, session_key) == 2
    end

    test "tracks transitions", %{ session_key: session_key } do
      expire(session_key)

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

    test "expires inactive sessions" do
      expire_all_inactive

      query = """
        MATCH ()-[s:SESSION]->(:Page { exit: true })
        RETURN count(s) AS items_count
      """

      assert items_count(query) == 4
    end

    test "tracks transitions" do
      expire_all_inactive

      query = """
        MATCH ()-[t:TRANSITION]->(:Page { exit: true })
        RETURN count(t) AS items_count
      """

      assert items_count(query) == 1
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