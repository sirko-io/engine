defmodule Sirko.Db.TransitionTest do
  use ExUnit.Case

  doctest Sirko.Db.Transition

  import Support.Neo4jHelpers

  alias Sirko.Db, as: Db

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "track/1" do
    setup do
      session_keys = ["skey10", "skey11"]

      load_fixture("diverse_sessions")

      {:ok, [session_keys: session_keys]}
    end

    test "records transitions between pages", %{ session_keys: session_keys } do
      Db.Transition.track(session_keys)

      start_list = transition_between_pages({"start", true}, {"path", "/list"})

      assert start_list["count"] == 2
      assert start_list["updated_at"] != nil

      list_popular = transition_between_paths("/list", "/popular")

      assert list_popular["count"] == 3
      assert list_popular["updated_at"] != nil

      list_exit = transition_between_pages({"path", "/list"}, {"exit", true})

      assert list_exit["count"] == 1
      assert list_exit["updated_at"] != nil

      popular_exit = transition_between_pages({"path", "/popular"}, {"exit", true})

      assert popular_exit["count"] == 1
      assert popular_exit["updated_at"] != nil
    end

    test "increases counts for a transition when it exists", %{ session_keys: session_keys } do
      load_fixture("transitions")

      initial_transition = transition_between_paths("/list", "/popular")

      Db.Transition.track(session_keys)

      updated_transition = transition_between_paths("/list", "/popular")

      assert updated_transition["count"] == 7
      assert updated_transition["updated_at"] != initial_transition["updated_at"]
    end

    test "does not affect transitions which does not belong to the found session", %{ session_keys: session_keys } do
      load_fixture("transitions")

      Db.Transition.track(session_keys)

      list_details = transition_between_paths("/list", "/details")
      about_popular = transition_between_paths("/about", "/popular")

      assert list_details["count"] == 6
      assert about_popular["count"] == 2
    end
  end

  describe "predict/1" do
    setup do
      load_fixture("transitions")

      :ok
    end

    test "predicts the next path for the current path" do
      assert Db.Transition.predict("/list") == "/details"
    end

    test "returns nil when the current page is unknown" do
      assert Db.Transition.predict("/settings") == nil
    end

    test "takes the path with the most fresh transitions when there are 2 paths with identical counts" do
      assert Db.Transition.predict("/about") == "/popular"
    end
  end

  defp transition_between_pages({a_prop, a_val}, {b_prop, b_val}) do
    query = """
      MATCH (a:Page)-[transition:TRANSITION]->(b:Page)
      WHERE a[{a_prop}] = {a_val} AND b[{b_prop}] = {b_val}

      RETURN transition
    """

    params = %{
      "a_prop" => a_prop,
      "a_val"  => a_val,
      "b_prop" => b_prop,
      "b_val"  => b_val
    }

    [%{"transition" => transition}] = execute_query(query, params)

    transition
  end

  defp transition_between_paths(a_path, b_path) do
    transition_between_pages({"path", a_path}, {"path", b_path})
  end
end
