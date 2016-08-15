defmodule Sirko.Predictor do
  alias Sirko.Neo, as: Neo

  @doc """
  Returns the path of a page which most likely will be visited by a user.
  """
  def predict(current_path) do
    # TODO: move to Db.Transitions
    query = """
      MATCH (:Page {path: {current_path} })-[transition:TRANSITION]->(next_page:Page)
      RETURN next_page.path AS next_path
      ORDER BY transition.count DESC
      LIMIT 1;
    """

    case Neo.query(query, %{ current_path: current_path }) do
      [res] ->
        res["next_path"]
      [] ->
        nil
    end
  end
end
