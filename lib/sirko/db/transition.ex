defmodule Sirko.Db.Transition do
  @moduledoc """
  Methods for working with transition relations
  """

  alias Sirko.Neo4j, as: Neo4j

  @type session_key :: Sirko.Session.session_key()

  @doc """
  Iterates through the given list of session keys and updates counts of visits
  for transition relations which correspond the sessions.
  """
  @spec track(session_keys :: [session_key]) :: any
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

    Neo4j.query(query, %{keys: session_keys})
  end

  @doc """
  Finds sessions with the given keys and subtracts their counts from
  counts of corresponding transactions.
  """
  @spec exclude_sessions(session_keys :: [session_key]) :: any
  def exclude_sessions(session_keys) do
    query = """
      MATCH (a)-[s:SESSION]->(b)
      MATCH (a)-[t:TRANSITION]->(b)
      WHERE s.key IN {session_keys}
      SET t.count = t.count - s.count
    """

    Neo4j.query(query, %{session_keys: session_keys})
  end

  @doc """
  Returns a list of maps with pages which most likely will be visited.
  by a user. Every map contains the path, assets and confidence
  of visiting the page. All returned pages passes the given confidence threshold.

  If a page doesn't have the assets property, an empty list will be returned as
  a default value.

  Examples

     iex> Sirko.Db.Transition.predict("/details", 2, 0.1)
     [%{"confidence" => 0.3, "path" => "/project", "assets" => [...]},
     %{"confidence" => 0.5, "path" => "/blog", "assets" => [...]}]

  """
  @spec predict(current_path :: String.t(), limit :: integer, confidence_threshold :: integer) ::
          Neo4j.result()
  def predict(current_path, limit \\ 1, confidence_threshold \\ 0) do
    query = """
      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(p:Page)
      WHERE p.path IS NOT NULL
      WITH sum(t.count) AS total

      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(p:Page)
      WHERE p.path IS NOT NULL

      WITH t, p, total
      ORDER BY t.count DESC, t.updated_at DESC
      LIMIT {limit}

      WITH p, (toFloat(t.count) / toFloat(total)) AS confidence
      WHERE confidence >= {threshold}

      RETURN p.path AS path,
             COALESCE(p.assets, []) AS assets,
             confidence
    """

    opts = %{current_path: current_path, limit: limit, threshold: confidence_threshold}

    Neo4j.query(query, opts)
  end

  @doc """
  Removes all transitions which aren't in use anymore (they have 0 count).
  """
  @spec remove_idle() :: any
  def remove_idle do
    query = """
      MATCH ()-[t:TRANSITION]->()
      WHERE t.count = 0
      DELETE t
    """

    Neo4j.query(query)
  end
end
