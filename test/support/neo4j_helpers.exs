defmodule Support.Neo4jHelpers do
  alias Neo4j.Sips, as: Neo4j

  def execute_query(query, params \\ %{ }) do
    case Neo4j.query(Neo4j.conn, query, params) do
      {:ok, res} ->
        res
      {:error, [%{ "code" => _code, "message" => message }]} ->
        raise message
    end
  end

  def cleanup_db do
    Neo4j.query!(Neo4j.conn, "MATCH (n) DETACH DELETE n")
  end

  def load_fixture(name) do
    query = Path.join([__DIR__, "..", "fixtures", name <> ".cypher"])
    |> File.read!

    execute_query(query)
  end
end
