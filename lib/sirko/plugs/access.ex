defmodule Sirko.Plugs.Access do
  @moduledoc """
  Rejects requests from unknown clients. Currently, it is a very simple solution
  which relies on the referer.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _ \\ [])

  @doc """
  Returns the conn structure without verifying info in case of the OPTIONS request.
  Some browsers (Firefox) don't send the referer header with this kind of the request.
  """
  def call(%{method: "OPTIONS"} = conn, _), do: conn

  def call(conn, _) do
    # TODO: find a way to cache it
    {:ok, reg} = Regex.compile("^#{client_url()}")

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

  defp client_url do
    :sirko
    |> Application.get_env(:web)
    |> Keyword.get(:client_url)
  end
end
