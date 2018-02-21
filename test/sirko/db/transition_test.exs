defmodule Sirko.Db.TransitionTest do
  use ExUnit.Case

  import Support.Neo4jHelpers

  alias Sirko.Db, as: Db

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  describe "track/1" do
    setup do
      session_keys = ["skey10", "skey11"]

      load_fixture("diverse_sessions")

      {:ok, [session_keys: session_keys]}
    end

    test "records transitions between pages", %{session_keys: session_keys} do
      Db.Transition.track(session_keys)

      start_list = transition_between_pages({"path", "/"}, {"path", "/list"})

      assert start_list.properties["count"] == 2
      assert start_list.properties["updated_at"] != nil

      list_popular = transition_between_paths("/list", "/popular")

      assert list_popular.properties["count"] == 3
      assert list_popular.properties["updated_at"] != nil

      list_exit = transition_between_pages({"path", "/list"}, {"exit", true})

      assert list_exit.properties["count"] == 1
      assert list_exit.properties["updated_at"] != nil

      popular_exit = transition_between_pages({"path", "/popular"}, {"exit", true})

      assert popular_exit.properties["count"] == 1
      assert popular_exit.properties["updated_at"] != nil
    end

    test "increases counts for a transition when it exists", %{session_keys: session_keys} do
      load_fixture("transitions")

      initial_transition = transition_between_paths("/list", "/popular")

      Db.Transition.track(session_keys)

      updated_transition = transition_between_paths("/list", "/popular")

      assert updated_transition.properties["count"] == 7

      assert updated_transition.properties["updated_at"] !=
               initial_transition.properties["updated_at"]
    end

    test "does not affect transitions which does not belong to the found session", %{
      session_keys: session_keys
    } do
      load_fixture("transitions")

      Db.Transition.track(session_keys)

      list_details = transition_between_paths("/list", "/details")
      about_popular = transition_between_paths("/about", "/popular")

      assert list_details.properties["count"] == 6
      assert about_popular.properties["count"] == 2
    end
  end

  describe "exclude_sessions/1" do
    setup do
      session_keys = ["skey1", "skey2"]

      load_fixture("diverse_sessions")
      load_fixture("transitions")

      {:ok, [session_keys: session_keys]}
    end

    test "decreases counts for transitions matching the corresponding sessions", %{
      session_keys: session_keys
    } do
      initial_transition = transition_between_paths("/list", "/popular")

      assert initial_transition.properties["count"] == 4

      Db.Transition.exclude_sessions(session_keys)

      updated_transition = transition_between_paths("/list", "/popular")

      assert updated_transition.properties["count"] == 1
    end
  end

  describe "predict/2" do
    setup do
      load_fixture("transitions")

      :ok
    end

    test "returns a list of predicted pages" do
      assert Db.Transition.predict("/list", 2) == [
               %{
                 "confidence" => 6 / 14,
                 "path" => "/details",
                 "assets" => [
                   "details.js",
                   "app.js"
                 ]
               },
               %{
                 "confidence" => 4 / 14,
                 "path" => "/about",
                 "assets" => [
                   "about.js",
                   "app.js"
                 ]
               }
             ]
    end

    test "takes paths with the most fresh transitions when there are 2 paths with identical counts" do
      assert Db.Transition.predict("/about") == [
               %{
                 "confidence" => 2 / 4,
                 "path" => "/popular",
                 "assets" => nil
               }
             ]
    end

    test "returns only pages which pass confidence threshold" do
      assert Db.Transition.predict("/list", 2, 0.4) == [
               %{
                 "confidence" => 6 / 14,
                 "path" => "/details",
                 "assets" => [
                   "details.js",
                   "app.js"
                 ]
               }
             ]
    end

    test "returns an empty list when the current page is connected to exit" do
      assert Db.Transition.predict("/popular") == []
    end
  end

  describe "remove_idle/0" do
    setup do
      load_fixture("transitions")

      :ok
    end

    test "removes idle transitions" do
      query = """
        MATCH ()-[t:TRANSITION]->()
        WHERE t.count = 0
        RETURN count(t) > 0 AS exist
      """

      [%{"exist" => exist}] = execute_query(query)

      assert exist == true

      Db.Transition.remove_idle()

      [%{"exist" => exist}] = execute_query(query)

      assert exist == false
    end
  end
end
