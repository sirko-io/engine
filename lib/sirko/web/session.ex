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

  alias Sirko.Session

  @session_key_name "_spio_skey"
  @cookie_max_age 60 * 60 # 1 hour

  def call(conn) do
    { current_path, referrer_path, session_key } = extract_details(conn)

    session_key = Session.track(current_path, referrer_path, session_key)

    conn
    |> put_resp_cookie(@session_key_name, session_key, [max_age: @cookie_max_age])
  end

  defp extract_details(conn) do
    current_path = conn.query_params["cur"]
    referrer_path = conn.query_params["ref"]

    conn = fetch_cookies(conn)

    session_key = conn.req_cookies[@session_key_name]

    { current_path, referrer_path, session_key }
  end
end
