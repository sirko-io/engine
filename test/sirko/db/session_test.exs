defmodule Sirko.Db.SessionTest do
  use ExUnit.Case

  doctest Sirko.Db.Session

  import Support.Neo4jHelpers

  alias Sirko.Db, as: Db

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "track/2" do
    setup do
      info = [
        session_key:   "skey1",
        referrer_path: "/popular",
        current_path:  "/list"
      ]

      { :ok, info }
    end

    test "creates a relation between 2 pages", info do
      %{
        session_key:   session_key,
        referrer_path: referrer_path,
        current_path:  current_path
      } = info

      Db.Session.track(session_key, referrer_path, current_path)

      query = """
        MATCH (referral:Page)-[session:SESSION { key: {key} }]->(current:Page)
        RETURN referral, current, session
      """

      [%{
        "referral" => referral_page,
        "current"  => current_page,
        "session"  => session
      }] = execute_query(query, %{ key: session_key })

      assert referral_page.properties["path"] == referrer_path
      assert current_page.properties["path"] == current_path
      assert session.properties["occurred_at"] != nil
      assert session.properties["count"] == 1
    end

    test "does not create extra nodes when the page exists", info do
      %{
        referrer_path: referrer_path,
        current_path:  current_path
      } = info

      Db.Session.track("skey1", referrer_path, current_path)
      Db.Session.track("skey2", referrer_path, current_path)

      assert count_pages() == 2
    end

    test "updates the count field for the relation when the relation with the given key exists", info do
      %{
        session_key:   session_key,
        referrer_path: referrer_path,
        current_path:  current_path
      } = info

      Db.Session.track(session_key, referrer_path, current_path)
      Db.Session.track(session_key, referrer_path, current_path)

      query = """
        MATCH (:Page)-[session:SESSION { key: {key} }]->(:Page)
        RETURN session
      """

      [%{
        "session"  => session
      }] = execute_query(query, %{ key: session_key })

      assert session.properties["count"] == 2
    end
  end

  describe "expire/1" do
    setup do
      session_keys = ["skey20", "skey21"]

      load_fixture("diverse_sessions")

      Db.Session.expire(session_keys)

      { :ok, [session_keys: session_keys] }
    end

    test "creates relations to the exit point", %{ session_keys: session_keys } do
      [s_key1, s_key2] = session_keys

      assert count_expired_sessions(s_key1) == 1
      assert count_expired_sessions(s_key2) == 1
    end

    test "does not affect foreign sessions" do
      assert count_expired_sessions("skey22") == 0
    end
  end

  describe "active?/1" do
    setup do
      load_fixture("diverse_sessions")

      :ok
    end

    test "returns true when there is an active session with the given key" do
      assert Db.Session.active?("skey31") == true
    end

    test "returns false when there is not a session with the given key" do
      assert Db.Session.active?("invalid-session-key") == false
    end

    test "returns false when a session with the given key got expired" do
      assert Db.Session.active?("skey10") == false
    end
  end

  describe "all_inactive/1" do
    setup do
      load_fixture("diverse_sessions")

      :ok
    end

    test "returns keys of sessions which are inactive for 1 hr" do
      session_keys = Db.Session.all_inactive(3600 * 1000)

      assert session_keys |> Enum.sort == ["skey20", "skey21", "skey22", "skey23"]
    end
  end

  describe "all_stale/1" do
    setup do
      load_fixture("diverse_sessions")

      :ok
    end

    test "returns keys of sessions which expired 7 days ago" do
      session_keys = Db.Session.all_stale(3600 * 1000 * 24 * 7)

      assert session_keys |> Enum.sort == ["skey1", "skey2"]
    end
  end

  describe "remove_stale/1" do
    setup do
      load_fixture("diverse_sessions")

      :ok
    end

    test "removes sessions which expired 7 days ago" do
      Db.Session.remove_stale(3600 * 1000 * 24 * 7)

      assert count_sessions("skey1") == 0
      assert count_sessions("skey2") == 0
    end

    test "does not affect other sessions" do
      Db.Session.remove_stale(3600 * 1000 * 24 * 7)

      assert count_sessions("skey21") == 2
    end
  end

  defp count_expired_sessions(session_key) do
    query = """
      MATCH (:Page { path: "/popular" })-[s:SESSION { key: {key}, count: 1 }]->(:Page { exit: true })
      RETURN count(s) AS count
    """

    [%{ "count" => count }] = execute_query(query, %{ key: session_key })

    count
  end
end
