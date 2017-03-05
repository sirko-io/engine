defmodule Sirko.Neo4j do
  @moduledoc """
  A simple wrapper for Neo4j to execute queries
  """

  require Logger

  alias Bolt.Sips, as: Bolt

  def query(query, params \\ %{ }) do
    case Bolt.query(Bolt.conn, query, params) do
      {:ok, res} ->
        res
      {:error, [%{ "code" => code, "message" => message }]} ->
        Logger.error(code <> message <> "\nQuery:\n" <> query)

        raise message
    end
  end
end
