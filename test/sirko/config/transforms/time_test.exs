defmodule Sirko.Config.Transforms.TimeTest do
  use ExUnit.Case, async: true

  import Sirko.Config.Transforms.Time

  describe "transform/2 the inactive_session_in key is given" do
    test "converts to milliseconds" do
      assert transform(:inactive_session_in, 1) == 60_000
    end
  end

  describe "transform/2 the stale_session_in key is given" do
    test "converts to milliseconds" do
      assert transform(:stale_session_in, 1) == 86_400_000
    end
  end

  describe "transform/2 an unknown key is given" do
    test "returns the given value as it is" do
      assert transform(:name, "test app") == "test app"
    end
  end
end
