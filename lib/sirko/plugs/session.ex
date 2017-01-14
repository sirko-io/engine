defmodule Sirko.Plugs.Session do
  @moduledoc """
  Maintains a user session.

  If it is a new user, a unique session key gets assigned through cookies
  to the browser in order to track visited pages by the user.

  If it is a returned user, the current page will be added to the chain of
  visited pages by the user. The expiry date of the session key gets prolonged.
  The idea is to expire the cookie in the browser and the session in the DB at the same time.
  """

  import Plug.Conn
  import Sirko.Url, only: [ extract_path: 1 ]

  alias Sirko.Session

  @session_key_name "_spio_skey"
  @cookie_max_age 60 * 60 # 1 hour

  def init(opts), do: opts

  def call(conn, opts \\ []) do
    match(conn, conn.request_path, Keyword.get(opts, :on))
  end

  defp match(conn, given_path, expected_path) when given_path == expected_path do
    conn = fetch_query_params(conn) |> fetch_cookies

    referral_path = conn.query_params["ref"] |> extract_path
    current_path = conn.query_params["cur"] |> extract_path

    session_key = conn.req_cookies[@session_key_name]

    track(conn, current_path, referral_path, session_key)
  end

  defp match(conn, _, _), do: conn

  # TODO: move to some validation plug?
  defp track(conn, nil, _, _) do
    conn
    |> send_resp(422, "")
    |> halt
  end

  defp track(conn, current_path, referral_path, session_key) do
    session_key = Session.track(current_path, referral_path, session_key)

    conn
    |> put_resp_cookie(@session_key_name, session_key, [max_age: @cookie_max_age])
  end
end
