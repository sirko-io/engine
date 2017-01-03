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
      SET t.updated_at = timestamp()
    """

    Neo.query(query, %{ session_key: session_key })
  end

  @doc """
  Returns the path of a page which most likely will be visited by a user.
  """
  def predict(current_path) do
    query = """
      MATCH (:Page {path: {current_path} })-[t:TRANSITION]->(next_page:Page)
      RETURN next_page.path AS next_path
      ORDER BY t.count DESC, t.updated_at DESC
      LIMIT 1;
    """

    case Neo.query(query, %{ current_path: current_path }) do
      [res] ->
        res["next_path"]
      _ ->
        nil
    end
  end
end