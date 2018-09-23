defmodule Sirko.Config.Transforms.Time do
  @moduledoc """
  Converts time to milliseconds.
  """

  use Toml.Transform

  def transform(:inactive_session_in, time_in_mins) do
    time_in_mins * 60 * 1000
  end

  def transform(:stale_session_in, time_in_days) do
    time_in_days * 24 * 3600 * 1000
  end

  def transform(_k, v), do: v
end
