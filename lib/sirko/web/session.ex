defmodule Sirko.Web.Session do
  @moduledoc """
  Maintains a user session.

  If it is a new user, a unique session key gets assigned through cookies
  to the browser in order to track visited pages by the user.

  If it is a returned user, the current page will be added to the chain of
  visited pages by the user. The expiry date of the session key gets prolonged.
  The idea is to expire the cookie in the browser and the session in the DB at the same time.
  """

  import Plug.Conn

  alias Sirko.{Session, Entry}

  @cookie_name "_spio_skey"

  def call(conn, params) do
    {entry, session_key} = extract_details(conn, params)

    session_key = Session.track(entry, session_key)

    conn
    |> put_session_key(session_key)
  end

  defp extract_details(conn, params) do
    entry = %Entry{
      current_path:  params["current"],
      referrer_path: params["referrer"],
      assets:        params["assets"]
    }

    conn = fetch_cookies(conn)

    session_key = conn.req_cookies[@cookie_name]

    {entry, session_key}
  end

  defp put_session_key(conn, nil), do: conn

  defp put_session_key(conn, session_key) do
    conn
    |> put_resp_cookie(@cookie_name, session_key, [max_age: cookie_max_age()])
  end

  defp cookie_max_age do
    :sirko
    |> Application.get_env(:engine)
    |> Keyword.fetch!(:inactive_session_in)
    |> div(1000)
  end
end
