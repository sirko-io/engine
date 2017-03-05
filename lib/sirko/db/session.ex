defmodule Sirko.Db.Session do
  @moduledoc """
  This module provides methods for working with users' sessions stored in the graph
  as relations between pages (nodes represent pages).

  Each user visiting a site gets an unique session key.
  That key allows to observe users' navigation between pages.
  """

  alias Sirko.Neo4j, as: Neo4j

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

    Neo4j.query(query, %{ key: session_key, path: current_path })
  end

  @doc """
  Do nothing if the referrer is nil. We cannot track a transition,
  because it hasn't happened yet.
  """
  def track(_, nil, _), do: nil

  @doc """
  Creates a session relation between 2 visited pages if it is
  a first transition between those pages during the current session.
  Otherwise, the relation will be updated to reflect a number of times
  the transition happened during the current session.
  """
  def track(session_key, referrer_path, current_path) do
    query = """
      MERGE (referrer:Page { path: {referrer_path} })
      MERGE (current:Page { path: {current_path} })
      MERGE (referrer)-[s:SESSION { key: {key} }]->(current)
      ON CREATE SET s.occurred_at = timestamp(), s.count = 1
      ON MATCH SET s.occurred_at = timestamp(), s.count = s.count + 1
    """

    Neo4j.query(
      query,
      %{ key: session_key, referrer_path: referrer_path, current_path: current_path }
    )
  end

  @doc """
  A session is treated as expired when it is connected to the exit point. Therefore,
  this method iterates through the given list of session keys and creates relations between
  last visited pages and the exit point.
  """
  def expire(session_keys) do
    query = """
      MATCH ()-[s:SESSION]->()
      WHERE s.key IN {keys}

      WITH s
      ORDER BY s.occurred_at

      WITH s.key AS key, last(collect(s)) AS last_hit

      WITH key, endNode(last_hit) AS last_page

      MERGE (exit:Page { exit: true })

      CREATE (last_page)-[new_s:SESSION]->(exit)
      SET new_s.key = key,
          new_s.expired_at = timestamp(),
          new_s.count = 1
    """

    Neo4j.query(query, %{ keys: session_keys })
  end

  @doc """
  Returns true if a session relation with the given key exists and
  it isn't expired. Otherwise, false.
  """
  def active?(session_key) do
    query = """
      MATCH ()-[s:SESSION { key: {key} }]->()
      RETURN (s.expired_at IS NULL) AS active
      ORDER BY s.occurred_at DESC
      LIMIT 1
    """

    case Neo4j.query(query, %{ key: session_key }) do
      [%{ "active" => active }] ->
        active
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

      RETURN collect(key) as keys
    """

    [%{"keys" => keys}] = Neo4j.query(query, %{ time: time })

    keys
  end

  @doc """
  Removes inactive sessions having one transition. A session is considered to be inactive
  if the last transition happened more than the given time in milliseconds.
  """
  def remove_all_short(time) do
    query = """
      MATCH ()-[s:SESSION]->()

      WITH s
      ORDER BY s.occurred_at

      WITH s.key AS key, collect(s) AS chain
      WITH chain, last(chain) AS last_hit
      WHERE last_hit.expired_at IS NULL AND timestamp() - last_hit.occurred_at > {time}

      WITH last_hit, size(chain) AS chain_length
      WHERE chain_length = 1

      DETACH DELETE last_hit
    """

    Neo4j.query(query, %{ time: time })
  end

  @doc """
  Returns a list of session keys which are expired for the given number of milliseconds.
  """
  def all_stale(time) do
    query = """
      MATCH ()-[s:SESSION]->()
      WHERE timestamp() - s.expired_at > {time}
      RETURN collect(s.key) as keys
    """

    [%{"keys" => keys}] = Neo4j.query(query, %{ time: time })

    keys
  end

  @doc """
  Removes sessions which are expired for the given number of milliseconds.
  """
  def remove_stale(time) do
    query = """
      MATCH ()-[s:SESSION]->()
      WHERE timestamp() - s.expired_at > {time}

      MATCH ()-[sess:SESSION {key: s.key}]->()
      DELETE sess
    """

    Neo4j.query(query, %{ time: time })
  end
end
