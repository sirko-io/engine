defmodule Sirko.Db.Page do
  alias Sirko.Neo, as: Neo

  @doc """
  Removes pages which don't have any inbound/outbound relations.
  """
  def remove_lonely do
    query = """
      MATCH (page:Page)
      WHERE NOT((page:Page)-->()) AND NOT(()-->(page:Page))
      DELETE page
    """

    Neo.query(query)
  end
end
