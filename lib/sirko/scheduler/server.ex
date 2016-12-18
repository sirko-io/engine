defmodule Sirko.Scheduler.Server do
  require Logger

  use GenServer

  @default_timeout 60 * 60 * 1000 # 1 hour

  @moduledoc """
  This module is kind of a worker which gets launched each N milliseconds and
  expires stale sessions. The infinite loop is achieved by using the timeout
  feature of GenServer (https://hexdocs.pm/elixir/GenServer.html#c:init/1).
  Each N milliseconds the handle_info callback gets called to expire stale sessions, once the job is done,
  the server waits N milliseconds to call the handle_info callback again.
  """

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    {:ok, timeout, timeout}
  end

  # Callbacks

  def handle_info(:timeout, timeout) do
    expire_sessions

    {:noreply, timeout, timeout}
  end

  defp expire_sessions do
    Sirko.Session.expire_all_inactive
  end
end
