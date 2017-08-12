defmodule Sirko.DbIndexes do
  @moduledoc """
  The purpose of this module is to add missing indexes while launching
  the application. Once indexes are added, the process terminates.

  This approach allows adding indexes without effecting the launch time
  of the application.
  """

  use Task, restart: :transient

  alias Sirko.Neo4j, as: Neo4j

  def start_link(_) do
    Task.start_link(__MODULE__, :add_indexes, [])
  end

  def add_indexes do
    add_index_to_page()
  end

  defp add_index_to_page do
    Neo4j.query("CREATE INDEX ON :Page(path)")
  end
end
