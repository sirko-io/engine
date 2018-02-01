defmodule Sirko.Neo4j do
  @moduledoc """
  A simple wrapper for Neo4j to execute queries
  """

  require Logger

  alias Bolt.Sips, as: Bolt

  @doc """
  Executes the given query and logs the duration of its execution.
  Raises an error if the query fails.
  """
  def query(query, params \\ %{}) do
    {duration, query_res} = :timer.tc(Bolt, :query, [Bolt.pool_name(), query, params])

    Logger.info(fn ->
      "Neo4j query (#{time_in_msec(duration)}ms):\n#{query} Params: #{inspect(params)}"
    end)

    case query_res do
      {:ok, res} ->
        res

      {:error, [%{"code" => code, "message" => message}]} ->
        Logger.error("#{code} #{message}\nQuery:\n#{query}")

        raise message
    end
  end

  defp time_in_msec(time_in_microsec) do
    (time_in_microsec / 1000)
    |> Float.round(1)
  end
end
