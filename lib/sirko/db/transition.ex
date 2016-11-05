defmodule Sirko.Db.Transition do
  alias Sirko.Neo, as: Neo

  @doc """
  Records transitions between pages supplied by the given session.
  """
  def track(session_key) do
    query = """
      MATCH (a)-[s:SESSION { key: {session_key} }]->(b)
      MERGE (a)-[t:TRANSITION]->(b)
      ON CREATE SET t.count = s.count
      ON MATCH SET t.count = t.count + s.count
    """

    Neo.query(query, %{ session_key: session_key })
  end
end