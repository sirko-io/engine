defmodule Sirko.Config.Transforms.AtomTest do
  use ExUnit.Case, async: true

  import Sirko.Config.Transforms.Atom

  describe "transform/2 the level key is given" do
    test "returns an atom" do
      assert transform(:level, "debug") == :debug
    end
  end

  describe "transform/2 an unknown key is given" do
    test "returns the given value as it is" do
      assert transform(:name, "test app") == "test app"
    end
  end
end
