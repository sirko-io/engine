defmodule Sirko.Neo do
  require Logger

  alias Neo4j.Sips, as: Neo4j

  @moduledoc """
  A simple wrapper for Neo4j to execute queries
  """

  def query(query, params \\ %{ }) do
    case Neo4j.query(Neo4j.conn, query, params) do
      {:ok, res} ->
        res
      {:error, [%{ "code" => code, "message" => message }]} ->
        Logger.error(code <> message <> "\nQuery:\n" <> query)

        raise message
    end
  end
end
