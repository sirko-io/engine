defmodule Sirko.Db.Transition do
  alias Sirko.Neo, as: Neo

  @doc """
  Records transitions between pages supplied by the given session.
  """
  def track(session_key) do
    query = """
      MATCH (a)-[:SESSION { key: {session_key} }]->(b)
      MERGE (a)-[t:TRANSITION]->(b)
      ON CREATE SET t.count = 1
      ON MATCH SET t.count = t.count + 1
    """

    Neo.query(query, %{ session_key: session_key })
  end
end