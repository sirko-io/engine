defmodule Sirko.Db.PageTest do
  use ExUnit.Case

  doctest Sirko.Db.Page

  import Support.Neo4jHelpers

  alias Sirko.Db, as: Db

  setup do
    on_exit fn ->
      cleanup_db()
    end

    :ok
  end

  describe "remove_lonely/0" do
    setup do
      load_fixture("transitions")
    end

    test "removes pages without relations" do
      assert page_exist?("/lonely") == true

      Db.Page.remove_lonely()

      assert page_exist?("/lonely") == false
    end

    test "does not affect other pages" do
      Db.Page.remove_lonely()

      assert count_pages() == 7
    end
  end
end
