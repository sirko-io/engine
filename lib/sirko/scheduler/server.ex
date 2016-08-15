defmodule Sirko.Scheduler.Server do
  require Logger

  use GenServer

  @default_timeout 60 * 60 * 1000 # 1 hour

  @moduledoc """
  This module is kind of a worker which gets launched each N secs and
  expires stale sessions. The infinite loop is achieved by using the timeout
  feature of GenServer (http://elixir-lang.org/docs/stable/elixir/GenServer.html#c:handle_cast/2).
  Each N secs the handle_info callback gets called to expire stale sessions, once the job is done,
  the server waits N secs to call the handle_info callback again.
  """

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_timeout(pid) do
    GenServer.cast(pid, :start_timeout)
  end

  def init(opts) do
    start_timeout(self)

    timeout = Keyword.get(opts, :timeout, @default_timeout)

    {:ok, timeout}
  end

  # Callbacks

  def handle_cast(:start_timeout, timeout) do
    handle_info(:timeout, timeout)
  end

  def handle_info(:timeout, timeout) do
    expire_sessions

    {:noreply, timeout, timeout}
  end

  defp expire_sessions do
    Sirko.Session.expire_all_inactive
  end
end
