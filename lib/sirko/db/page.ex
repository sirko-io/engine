defmodule Sirko.Db.Page do
  @moduledoc """
  A list of methods for working with a Page node which represents
  a real page on a site.
  """

  alias Sirko.Neo4j, as: Neo4j

  @doc """
  Removes pages which don't have any inbound/outbound relations.
  """
  @spec remove_lonely() :: any
  def remove_lonely do
    query = """
      MATCH (page:Page)
      WHERE NOT((page:Page)-->()) AND NOT(()-->(page:Page))
      DELETE page
    """

    Neo4j.query(query)
  end
end
