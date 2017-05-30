defmodule Sirko.Session do
  @moduledoc """
  This module provides methods to track a user session.

  The session is crucial element in the prediction solution.
  The module tracks how users navigate a site. The session is considered as a chain
  of visited pages by a particular user.
  """

  alias Sirko.Db, as: Db

  @default_key_length 32

  # how many session keys must be processed in one cypher query
  @chunk_sessions_on 100

  @doc """
  Creates a new session relation in the DB and returns a unique session key
  which is used later in order to identify a being tracked session.
  """
  def track(current_path, _, nil) do
    session_key = generate_key()

    Db.Session.create(session_key, current_path)

    session_key
  end

  @doc """
  Adds the given page to the chain of visited pages by a particular user.
  If the given session key belongs to an expired session, a new session gets started.
  """
  def track(current_path, referrer_path, session_key) do
    if Db.Session.active?(session_key) do
      Db.Session.track(session_key, referrer_path, current_path)
      session_key
    else
      track(current_path, referrer_path, nil)
    end
  end

  @doc """
  Expires sessions found by the given list of session keys,
  increases counts on transition relations which link visited pages within the sessions.
  """
  def expire(session_keys) do
    Db.Session.expire(session_keys)
    Db.Transition.track(session_keys)
  end

  @doc """
  Finds and expires sessions which are inactive for `inactive_session_in` milliseconds.
  Short sessions get removed, they don't bring any value to the prediction model.
  """
  def expire_all_inactive(inactive_session_in) do
    Db.Session.remove_all_short(inactive_session_in)

    inactive_session_in
    |> Db.Session.all_inactive
    |> Enum.chunk(@chunk_sessions_on, @chunk_sessions_on, [])
    |> Enum.each(fn(keys) -> expire(keys) end)
  end

  defp generate_key do
    # TODO: does it provide a unique value?
    @default_key_length
    |> :crypto.strong_rand_bytes
    |> Base.encode16(case: :lower)
  end
end
