defmodule Sirko.Db.Transition do
  alias Sirko.Neo4j, as: Neo4j

  @doc """
  Iterates through the given list of session keys and updates counts of visits
  for transition relations which correspond the sessions.
  """
  def track(session_keys) do
    query = """
      MATCH (a)-[s:SESSION]->(b)
      WHERE s.key IN {keys}

      MERGE (a)-[t:TRANSITION]->(b)

      WITH t, s, CASE
        WHEN t.updated_at > s.occurred_at THEN t.updated_at
        WHEN NOT exists(s.occurred_at) THEN s.expired_at
        ELSE s.occurred_at
      END AS updated_at

      SET t.count = coalesce(t.count, 0) + s.count,
          t.updated_at = updated_at
    """

    Neo4j.query(query, %{ keys: session_keys })
  end

  @doc """
  Finds sessions with the given keys and subtracts their counts from
  counts of corresponding transactions.
  """
  def exclude_sessions(session_keys) do
    query = """
      MATCH (a)-[s:SESSION]->(b)
      MATCH (a)-[t:TRANSITION]->(b)
      WHERE s.key IN {session_keys}
      SET t.count = t.count - s.count
    """

    Neo4j.query(query, %{ session_keys: session_keys })
  end

  @doc """
  Returns the path of a page which most likely will be visited by a user.
  """
  def predict(current_path) do
    query = """
      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(next_page:Page)
      RETURN next_page.path AS next_path
      ORDER BY t.count DESC, t.updated_at DESC
      LIMIT 1
    """

    case Neo4j.query(query, %{ current_path: current_path }) do
      [res] ->
        res["next_path"]
      _ ->
        nil
    end
  end

  @doc """
  Removes all transitions which aren't in use anymore (they have 0 count).
  """
  def remove_idle do
    query = """
      MATCH ()-[t:TRANSITION]->()
      WHERE t.count = 0
      DELETE t
    """

    Neo4j.query(query)
  end
end
