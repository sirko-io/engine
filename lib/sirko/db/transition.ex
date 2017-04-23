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
  Returns a map representing info about a possible page which most likely will be
  visited by a user. The returned map contains the path to the page, the count
  of transitions made to the page and the total number of transitions made from the current page.

  Examples

     iex> Sirko.Db.Transition.predict("/details")
     %{"path" => "/project", "count" => 5, "total" => 15}

  """
  def predict(current_path) do
    query = """
      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(p:Page)

      WITH t, p
      ORDER BY t.count DESC, t.updated_at DESC
      LIMIT 1

      WITH p.path AS path, t.count AS count

      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(:Page)
      WITH sum(t.count) AS total, count, path

      RETURN path, count, total
    """

    case Neo4j.query(query, %{ current_path: current_path }) do
      [res] -> res
      _ -> nil
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
