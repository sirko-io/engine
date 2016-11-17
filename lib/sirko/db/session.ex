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
      CREATE (start)-[s:SESSION { key: {key}, count: 1 }]->(current)
      SET s.occurred_at = timestamp()
    """

    Neo.query(query, %{ key: session_key, path: current_path })
  end

  @doc """
  Creates a session relation between 2 visited pages if it is
  a first transition between those pages during the current session.
  Otherwise, the relation will be updated to reflect a number of times
  the transition happened during the current session.
  """
  def track(session_key, referral_path, current_path) do
    query = """
      MATCH (referral:Page { path: {referral_path} })
      MERGE (current:Page { path: {current_path} })
      MERGE (referral)-[s:SESSION { key: {key} }]->(current)
      ON CREATE SET s.occurred_at = timestamp(), s.count = 1
      ON MATCH SET s.occurred_at = timestamp(), s.count = s.count + 1
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
    query = """
      MATCH (:Page { start: true })-[:SESSION * { key: {key} }]->(n:Page)
      WITH last(collect(n)) AS last_page
      MERGE (exit:Page { exit: true })
      CREATE (last_page)-[s:SESSION { key: {key} }]->(exit)
      SET s.expired_at = timestamp(), s.count = 1
    """

    Neo.query(query, %{ key: session_key })
  end

  @doc """
  Returns true if a session relation with the given key exists and
  it isn't expired. Otherwise, false.
  """
  def active?(session_key) do
    query = """
      MATCH ()-[s:SESSION { key: {key} }]->()
      RETURN s AS last_hit
      ORDER BY s.occurred_at DESC
      LIMIT 1
    """

    case Neo.query(query, %{ key: session_key }) do
      [%{ "last_hit" => last_hit }] ->
        !last_hit["expired_at"]
      _ ->
        false
    end
  end

  @doc """
  Returns a list of session keys which are inactive for the given number of milliseconds.
  """
  def all_inactive(time) do
    query = """
      MATCH ()-[s:SESSION]->()
      WITH s
      ORDER BY s.occurred_at
      WITH s.key AS key, last(collect(s)) AS last_hit
      WHERE last_hit.expired_at IS NULL AND timestamp() - last_hit.occurred_at > {time}
      RETURN collect(last_hit.key) as keys
    """

    [%{"keys" => keys}] = Neo.query(query, %{ time: time })

    keys
  end
end
