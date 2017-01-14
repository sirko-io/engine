defmodule Sirko.AssetsPlugin do
  @moduledoc """
  Makes sure the js client is installed before building a release.
  """

  use Mix.Releases.Plugin

  def before_assembly(_release, _opts) do
    case System.cmd("npm", ["install"]) do
      {_, 0} ->
        nil
      {output, error_code} ->
        {:error, output, error_code}
    end

    nil
  end

  def after_assembly(_, _), do: nil
  def before_package(_, _), do: nil
  def after_package(_, _), do: nil
  def after_cleanup(_, _), do: nil
end
