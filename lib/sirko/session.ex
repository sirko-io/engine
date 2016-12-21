defmodule Sirko.Session do
  @moduledoc """
  This module provides methods to track a user session.

  The session is crucial element in the prediction solution.
  The module tracks how users navigate a site. The session is considered as a chain
  of visited pages by a particular user.
  """

  alias Sirko.Db, as: Db

  @default_key_length 32

  @inactive_session_in 60 * 60 * 1000 # 1 hour

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
  def track(current_path, referral_path, session_key) do
    if Db.Session.active?(session_key) do
      Db.Session.track(session_key, referral_path, current_path)
      session_key
    else
      track(current_path, referral_path, nil)
    end
  end

  @doc """
  Expires a session having the given key and increases counts on transition relations which
  link visited pages within the session.
  """
  def expire(session_key) do
    Db.Session.expire(session_key)
    Db.Transition.track(session_key)
  end

  @doc """
  Finds and expires sessions which are inactive for last `@inactive_session_in` milliseconds.
  Short sessions get removed, they don't bring any value to the prediction model.
  """
  def expire_all_inactive do
    Db.Session.remove_all_short(@inactive_session_in)

    Db.Session.all_inactive(@inactive_session_in)
    |> Enum.each(fn(key) -> expire(key) end)
  end

  defp generate_key do
    # TODO: does it provide a unique value?
    :crypto.strong_rand_bytes(@default_key_length)
    |> Base.encode16(case: :lower)
  end
end
