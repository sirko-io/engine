defmodule Support.Neo4jHelpers do
  alias Bolt.Sips, as: Bolt

  def execute_query(query, params \\ %{}) do
    case Bolt.query(Bolt.pool_name(), query, params) do
      {:ok, res} ->
        res

      {:error, [code: _code, message: message]} ->
        raise message
    end
  end

  def cleanup_db do
    Bolt.query!(Bolt.pool_name(), "MATCH (n) DETACH DELETE n")
  end

  def load_fixture(name) do
    query =
      Path.join([__DIR__, "..", "fixtures", name <> ".cypher"])
      |> File.read!()

    execute_query(query)
  end

  def transition_between_pages({a_prop, a_val}, {b_prop, b_val}) do
    query = """
      MATCH (a:Page)-[transition:TRANSITION]->(b:Page)
      WHERE a[{a_prop}] = {a_val} AND b[{b_prop}] = {b_val}

      RETURN transition
    """

    params = %{
      "a_prop" => a_prop,
      "a_val" => a_val,
      "b_prop" => b_prop,
      "b_val" => b_val
    }

    [%{"transition" => transition}] = execute_query(query, params)

    transition
  end

  def transition_between_paths(a_path, b_path) do
    transition_between_pages({"path", a_path}, {"path", b_path})
  end

  def count_sessions(session_key) do
    query = """
      MATCH ()-[s:SESSION { key: {key} }]->()
      RETURN count(s) AS count
    """

    [%{"count" => count}] = execute_query(query, %{key: session_key})

    count
  end

  def count_pages do
    query = """
      MATCH (page:Page)
      RETURN count(page) AS count
    """

    [%{"count" => count}] = execute_query(query)

    count
  end

  def page_exist?(path) do
    query = """
      MATCH (page:Page { path: {path} })
      RETURN (count(page) > 0) AS res
    """

    [%{"res" => res}] = execute_query(query, %{path: path})

    res
  end
end
