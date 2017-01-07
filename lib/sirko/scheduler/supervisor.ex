defmodule Sirko.Scheduler.Supervisor do
  @moduledoc """
  This supervisor is responsible for monitoring following workers:

  - the worker for expiring inactive sessions
  - the worker for cleaning up stale data (sessions, transitions, pages)

  Each of those workers runs a loop in order to periodically execute
  a given callback.
  """

  use Supervisor

  alias Sirko.Scheduler.Worker

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children = [
      inactive_sessions_worker(opts),
      stale_data_worker(opts)
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp inactive_sessions_worker(opts) do
    expire_sessions_in = Keyword.get(opts, :expire_sessions_in)

    callback = fn ->
      Sirko.Session.expire_all_inactive
    end

    name = Sirko.Scheduler.InactiveSessions

    worker(
      Worker,
      [[timeout: expire_sessions_in, callback: callback, name: name]],
      id: name
    )
  end

  defp stale_data_worker(opts) do
    remove_stale_data_in = Keyword.get(opts, :remove_stale_data_in)

    callback = fn ->
      Sirko.Cleaner.clean_up
    end

    name = Sirko.Scheduler.Cleaner

    worker(
      Worker,
      [[timeout: remove_stale_data_in, callback: callback, name: name]],
      id: name
    )
  end
end
