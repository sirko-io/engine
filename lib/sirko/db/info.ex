defmodule Sirko.Db.Info do
  @moduledoc """
  A list of methods for getting overview of data kept in the DB.
  """

  alias Sirko.Neo4j, as: Neo4j

  @doc """
  Returns a count of transitions and pages in the DB.
  """
  @spec overview() :: Neo4j.result()
  def overview do
    query = """
      MATCH ()-[t:TRANSITION]->()
      WITH count(t) as transitions_count

      MATCH (p:Page) WHERE p.exit IS NULL
      WITH count(p) as pages_count, transitions_count

      RETURN transitions_count, pages_count
    """

    Neo4j.query(query)
  end
end
