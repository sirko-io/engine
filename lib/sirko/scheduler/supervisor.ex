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
    engine_opts = Application.get_env(:sirko, :engine)

    children = [
      inactive_sessions_worker(opts, engine_opts),
      stale_data_worker(opts, engine_opts)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp inactive_sessions_worker(worker_opts, engine_opts) do
    expire_sessions_every = Keyword.get(worker_opts, :expire_sessions_every)
    inactive_session_in = Keyword.get(engine_opts, :inactive_session_in)

    callback = fn ->
      Sirko.Session.expire_all_inactive(inactive_session_in)
    end

    name = Sirko.Scheduler.InactiveSessions

    Supervisor.child_spec(
      {
        Worker,
        [timeout: expire_sessions_every, callback: callback, name: name]
      },
      id: name
    )
  end

  defp stale_data_worker(worker_opts, engine_opts) do
    remove_stale_data_every = Keyword.get(worker_opts, :remove_stale_data_every)
    stale_session_in = Keyword.get(engine_opts, :stale_session_in)

    callback = fn ->
      Sirko.Cleaner.clean_up(stale_session_in)
    end

    name = Sirko.Scheduler.Cleaner

    Supervisor.child_spec(
      {
        Worker,
        [timeout: remove_stale_data_every, callback: callback, name: name]
      },
      id: name
    )
  end
end
