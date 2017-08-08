defmodule Sirko.DbIndexes do
  @moduledoc """
  The purpose of this module is to add missing indexes while launching
  the application. Once indexes are added, the process terminates.

  This approach allows adding indexes without effecting the launch time
  of the application.
  """

  use GenServer

  alias Sirko.Neo4j, as: Neo4j

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # add indexes in 2 secs after start
    {:ok, nil, 2_000}
  end

  def handle_info(:timeout, _) do
    add_index_to_page()

    {:stop, :normal, nil}
  end

  defp add_index_to_page do
    Neo4j.query("CREATE INDEX ON :Page(path)")
  end
end
