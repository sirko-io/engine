defmodule Sirko.Scheduler.Worker do
  @moduledoc """
  This module is kind of a worker which gets launched each N milliseconds and
  executes the given callback. The infinite loop is achieved by using the timeout
  feature of GenServer (https://hexdocs.pm/elixir/GenServer.html#c:init/1).
  Each N milliseconds the handle_info callback gets called to call the given callback,
  once the job is done, the server waits N milliseconds to call the handle_info callback again.
  """

  use GenServer

  @default_timeout 60 * 60 * 1000 # 1 hour

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))
  end

  def init(opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    callback = Keyword.get(opts, :callback)

    {:ok, {timeout, callback}, timeout}
  end

  # Callbacks

  def handle_info(:timeout, {timeout, callback}) do
    callback.()

    {:noreply, {timeout, callback}, timeout}
  end
end
