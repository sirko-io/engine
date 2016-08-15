defmodule Sirko.Session do
  alias Sirko.Db, as: Db

  @default_key_length 32

  @inactive_session_in 60 * 60

  @moduledoc """
  This module provides method to track user's session.

  Session is crucial element in the prediction solution. Basically, this
  module tracks how users navigate a site. The session is considered as a chain
  of visited pages by a particular user. To make correct prediction visited pages
  must be linked in a real site.
  """

  @doc """
  Creates a new session record in the DB and returns a unique token
  which is used later in order to identify a being tracked session.
  """
  def start(page_path) do
    session_key = generate_key

    Db.Session.create(session_key, page_path)

    session_key
  end

  @doc """
  Adds another visited page to a chain of visited pages by a particular user.

  The chain must be smooth, there should not be any gaps in transitions. For example,
  if the user who has the assigned session key jumps to another page by typing the path
  in the address line of a browser, such transition should not be tracked. Such kind of transitions
  doesn't bring any value to the prediction.
  """
  def track(session_key, referral_path, current_path) do
    case Db.Session.exist(session_key) do
      true ->
        Db.Session.track(session_key, referral_path, current_path)

        { :ok }

      false ->
        { :new_session, start(current_path) }
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
  Finds sessions which are inactive for last `@inactive_session_in` hour and expires them.
  """
  def expire_all_inactive do
    session_keys = Db.Session.all_inactive(@inactive_session_in)

    Enum.each(session_keys, fn(key) -> expire(key) end)
  end

  defp generate_key do
    # TODO: does it provide a unique value?
    :crypto.strong_rand_bytes(@default_key_length)
    |> Base.encode16(case: :lower)
  end
end
