defmodule Sirko.Config.ProviderTest do
  use ExUnit.Case, async: true

  alias Sirko.Config.Provider

  import Application, only: [get_env: 2, put_env: 3]

  setup do
    settings = get_env(:bolt_sips, Bolt)

    on_exit(fn ->
      put_env(:bolt_sips, Bolt, settings)
    end)

    :ok
  end

  describe "init/1" do
    test "transfers settings from the neo4j to the bolt_sips namespace" do
      url = "bolt://localhost:1234"

      put_env(:neo4j, :url, url)

      Provider.init([])

      driver_url =
        get_env(:bolt_sips, Bolt)
        |> Keyword.get(:url)

      assert driver_url == url
    end
  end
end
