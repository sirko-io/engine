defmodule Sirko.Session do
  @moduledoc """
  This module provides methods to track a user session.

  The session is crucial element in the prediction solution.
  The module tracks how users navigate a site. The session is considered as a chain
  of visited pages by a particular user.
  """

  alias Sirko.{Db, Entry}

  # bytes
  @default_key_length 32

  # how many session keys must be processed in one cypher query
  @chunk_sessions_on 100

  @type session_key :: String.t()

  @doc """
  If the referrer is nil, do nothing. We cannot track a transition,
  because it hasn't happened yet

  If the given session key is nil, creates a unique session key and
  tracks the transition. It is a new user.

  Otherwise, adds the given page to the chain of visited pages by
  a particular user.  If the given session key belongs to an expired
  session, a new session gets started.
  """
  @spec track(entry :: Entry.t(), session_key | nil) :: session_key | nil
  def track(%Entry{referrer_path: nil}, _), do: nil

  def track(entry, nil) do
    session_key = generate_key()

    Db.Session.track(session_key, entry)
    session_key
  end

  def track(entry, session_key) do
    if Db.Session.active?(session_key) do
      Db.Session.track(session_key, entry)
      session_key
    else
      track(entry, nil)
    end
  end

  @doc """
  Expires sessions found by the given list of session keys,
  increases counts on transition relations which link visited pages within the sessions.
  """
  @spec expire(session_keys :: [session_key]) :: any
  def expire(session_keys) do
    Db.Session.expire(session_keys)
    Db.Transition.track(session_keys)
  end

  @doc """
  Finds and expires sessions which are inactive for `inactive_session_in` milliseconds.
  """
  @spec expire_all_inactive(inactive_session_in :: integer) :: any
  def expire_all_inactive(inactive_session_in) do
    inactive_session_in
    |> Db.Session.all_inactive()
    |> Enum.chunk_every(@chunk_sessions_on)
    |> Enum.each(fn keys -> expire(keys) end)
  end

  defp generate_key do
    # TODO: does it provide a unique value?
    @default_key_length
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
