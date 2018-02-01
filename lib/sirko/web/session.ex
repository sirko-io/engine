defmodule Sirko.Web.Session do
  @moduledoc """
  Maintains a user session.

  When a user has visited only 1 page, it does nothing.
  There is nothing to track yet.

  When a user has visited only 2 pages, it:
    - assigns a unique session key through cookies to track
      further visits of the user
    - adds a transition to the newly started session

  When a user has a session key, it:
    - adds a transition to the user's session
    - prolongs the expiry of the session key. The idea is
      to expire the cookie in the browser and the session
      in the DB at the same time.
  """

  import Plug.Conn

  alias Sirko.{Session, Entry}

  @cookie_name "_spio_skey"

  @doc """
  Returns a tuple which can be used to add the cookie to the response.
  So, the top level module doesn't know anything about this cookie, it only knows
  that it must be added.

  Returns nil, when a transition hasn't happened yet.
  """
  def call(conn, params) do
    {entry, session_key} = extract_details(conn, params)

    entry
    |> Session.track(session_key)
    |> build_cookie
  end

  defp extract_details(conn, params) do
    entry = %Entry{
      current_path: params["current"],
      referrer_path: params["referrer"],
      assets: params["assets"]
    }

    conn = fetch_cookies(conn)

    session_key = conn.req_cookies[@cookie_name]

    {entry, session_key}
  end

  defp build_cookie(nil), do: nil

  defp build_cookie(session_key) do
    {@cookie_name, session_key, [max_age: cookie_max_age()]}
  end

  defp cookie_max_age do
    :sirko
    |> Application.get_env(:engine)
    |> Keyword.fetch!(:inactive_session_in)
    |> div(1000)
  end
end
