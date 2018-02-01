defmodule Sirko.Scheduler.WorkerTest do
  use ExUnit.Case, async: true

  doctest Sirko.Scheduler.Worker

  alias Sirko.Scheduler.Worker

  test "calls the given function after the given amount of time" do
    # milliseconds
    timeout = 50

    self_pid = self()

    callback = fn -> send(self_pid, :called) end

    {:ok, _} = Worker.start_link(timeout: timeout, callback: callback)

    assert_receive :called, timeout + 10
  end
end
