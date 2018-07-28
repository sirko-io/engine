defmodule Sirko.Db.InfoTest do
  use ExUnit.Case

  doctest Sirko.Db.Info

  import Support.Neo4jHelpers

  alias Sirko.Db

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  describe "overview/0" do
    setup do
      load_fixture("transitions")
    end

    test "returns a count of transitions and pages" do
      [%{"transitions_count" => transitions_count, "pages_count" => pages_count}] =
        Db.Info.overview()

      assert transitions_count == 10
      assert pages_count == 7
    end
  end
end
