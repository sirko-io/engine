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
      session_key = "skey10"

      load_fixture("diverse_sessions")

      {:ok, [session_key: session_key]}
    end

    test "records transitions between pages", %{ session_key: session_key } do
      Db.Transition.track(session_key)

      [start_list, list_popular, popupar_exit] = all_transitions()

      assert start_list["count"] == 1
      assert start_list["updated_at"] != nil

      assert list_popular["count"] == 2
      assert list_popular["updated_at"] != nil

      assert popupar_exit["count"] == 1
      assert popupar_exit["updated_at"] != nil
    end

    test "increases counts for a transition when it exists", %{ session_key: session_key } do
      load_fixture("transitions")

      initial_transition = transition_between_paths("/list", "/popular")

      Db.Transition.track(session_key)

      updated_transition = transition_between_paths("/list", "/popular")

      assert updated_transition["count"] == 6
      assert updated_transition["updated_at"] != initial_transition["updated_at"]
    end

    test "does not affect transitions which does not belong to the given session", %{ session_key: session_key } do
      load_fixture("transitions")

      Db.Transition.track(session_key)

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

  defp all_transitions do
    query = """
      MATCH (:Page { start: true })-[transitions:TRANSITION *]->(:Page { exit: true })
      RETURN transitions
    """

    [%{"transitions" => transitions}] = execute_query(query)

    transitions
  end

  defp transition_between_paths(path_a, path_b) do
    query = """
      MATCH (:Page { path: {a} })-[transition:TRANSITION]->(:Page { path: {b} })
      RETURN transition
    """

    [%{"transition" => transition}] = execute_query(query, %{ "a" => path_a, "b" => path_b })

    transition
  end
end
