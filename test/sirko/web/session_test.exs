defmodule Sirko.Web.SessionTest do
  use ExUnit.Case
  use Plug.Test

  import Support.Neo4jHelpers

  import Sirko.Web.Session, only: [call: 2]

  setup do
    on_exit(fn ->
      cleanup_db()
    end)

    :ok
  end

  test "returns nil when the transition hasn't happened yet" do
    res =
      conn(:post, "/")
      |> call(%{"current" => "/list"})

    assert res == nil
  end

  test "returns a tuple with a session key when the transition has happened" do
    res =
      conn(:post, "/")
      |> call(%{
        "current" => "/list",
        "referrer" => "/home",
        "assets" => ["http://example.org"]
      })

    {name, session_key, opts} = res

    assert name == "_spio_skey"
    assert session_key != nil
    assert opts[:max_age] == 3600
  end
end
