defmodule Sirko.Config.Transforms.Atom do
  @moduledoc """
  Converts values to atoms.
  """

  use Toml.Transform

  def transform(:level, val) do
    val |> String.to_atom()
  end

  def transform(_k, v), do: v
end
