defmodule Sirko.Importers.GoogleAnalyticsTest do
  use ExUnit.Case

  import Support.Neo4jHelpers

  alias Sirko.Importers.GoogleAnalytics

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  test "creates sessions and pages" do
    import_ga_data()

    assert count_pages() == 3
    assert count_sessions() == 3

    query = """
      MATCH (:Page {path: "/popular"})-[s:SESSION]->(:Page {path: "/about"})
      RETURN s AS session
      ORDER BY s.occurred_at DESC
    """

    [
      %{"session" => a_session},
      %{"session" => b_session}
    ] = execute_query(query)

    assert a_session.properties["key"] == "2018072914"
    assert a_session.properties["occurred_at"] == 1_532_872_800_000
    assert a_session.properties["count"] == 3

    assert b_session.properties["key"] == "2018072808"
    assert b_session.properties["occurred_at"] == 1_532_764_800_000
    assert b_session.properties["count"] == 1
  end

  test "excludes sessions which related to refreshes" do
    import_ga_data()

    query = """
      MATCH (:Page {path: "/about"})-[s:SESSION]->(:Page {path: "/about"})
      RETURN count(s) AS count
    """

    [
      %{"count" => count}
    ] = execute_query(query)

    assert count == 0
  end

  test "returns a number of created sessions" do
    assert import_ga_data() == 3
  end

  test "returns 0 when there was nothing to insert because of filtering" do
    assert import_ga_data("only_refreshes") == 0
  end

  def ga_fixture(name) do
    [__DIR__, "..", "..", "fixtures", "google_analytics", "#{name}.json"]
    |> Path.join()
    |> File.read!()
    |> Poison.decode!()
  end

  def import_ga_data(name \\ "various") do
    ga_fixture(name)
    |> get_in(["reports"])
    |> List.first()
    |> get_in(["data", "rows"])
    |> GoogleAnalytics.import()
  end
end
