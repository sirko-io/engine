defmodule Sirko.Plugs.Access do
  @moduledoc """
  Rejects requests from unknown clients. Currently, it is a very simple solution
  which relies on the referer.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _ \\ []) do
    client_url = Application.get_env(:sirko, :web)
    |> Keyword.get(:client_url)

    # TODO: find a way to cache it
    {:ok, reg} = Regex.compile("^#{client_url}")

    case get_req_header(conn, "referer") do
      [referer] ->
        respond(conn, Regex.match?(reg, referer))
      _ ->
        reject(conn)
    end
  end

  defp respond(conn, true), do: conn

  defp respond(conn, false), do: reject(conn)

  defp reject(conn) do
    conn
    |> send_resp(422, "")
    |> halt
  end
end
