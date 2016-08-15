defmodule Sirko.Db.Session do
  @moduledoc """
  This module provides methods for working with users' sessions stored in the graph
  as relations between pages (nodes represent pages).

  Each user visiting a site gets an unique session key.
  That key allows to observe users' navigation between pages.
  """

  alias Sirko.Neo, as: Neo

  @doc """
  Creates a relation between the starting point and a page having the given path.
  If the page doesn't exist, it will be created first.
  """
  def create(session_key, current_path) do
    query = """
      MERGE (start:Page { start: true })
      MERGE (current:Page { path: {path} })
      CREATE (start)-[s:SESSION { key: {key} }]->(current)
      SET s.created_at = timestamp()
    """

    Neo.query(query, %{ key: session_key, path: current_path })
  end

  @doc """
  Creates a relation between 2 pages. Basically, it tracks a visited page by a user
  having the given session key. Since we consider navigation as a path, the referral page
  must be provided.
  """
  def track(session_key, referral_path, current_path) do
    query = """
      MATCH (referral:Page { path: {referral_path} })
      MERGE (current:Page { path: {current_path} })
      CREATE (referral)-[s:SESSION { key: {key} }]->(current)
      SET s.created_at = timestamp()
    """

    Neo.query(
      query,
      %{ key: session_key, referral_path: referral_path, current_path: current_path }
    )
  end

  @doc """
  Creates a relation between the last visited page by a user having the given session key
  and the exit point. After that, the whole session is treated as expired.
  """
  def expire(session_key) do
    # TODO: remove session if it is too short (visited one page only)

    query = """
      MATCH (:Page { start: true })-[:SESSION * { key: {key} }]->(n:Page)
      WITH last(collect(n)) AS last_page
      MERGE (exit:Page { exit: true })
      CREATE (last_page)-[s:SESSION { key: {key} }]->(exit)
      SET s.expired_at = timestamp()
    """

    Neo.query(query, %{ key: session_key })
  end

  @doc """
  Returns true if a session relation with the given key exist. Otherwise, false.

  ## Example:

      iex> session_key = "uniq-session-key"
      iex> Sirko.Db.Session.create(session_key, "/list")
      iex> Sirko.Db.Session.exist(session_key)
      true

      iex> Sirko.Db.Session.create("uniq-session-key", "/list")
      iex> Sirko.Db.Session.exist("fake-session-key")
      false
  """
  def exist(session_key) do
    query = """
      MATCH ()-[s:SESSION {key: {key} }]->()
      RETURN count(s) > 0 AS existence
    """

    [%{"existence" => existence}] = Neo.query(query, %{ key: session_key })

    existence
  end

  @doc """
  Returns a list of keys of sessions which are inactive for the given number of seconds.
  """
  def all_inactive(time) do
    query = """
      MATCH ()-[s:SESSION]->()
      WITH s
      ORDER BY s.created_at
      WITH s.key AS key, last(collect(s)) AS last_hit
      WHERE last_hit.expired_at IS NULL AND timestamp() - last_hit.created_at > {time}
      RETURN collect(last_hit.key) as keys
    """

    [%{"keys" => keys}] = Neo.query(query, %{ time: time })

    keys
  end
end
