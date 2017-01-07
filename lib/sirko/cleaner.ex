defmodule Sirko.Cleaner do
  @moduledoc """
  Takes care of removing needless and harmful data.
  """

  alias Sirko.Db, as: Db

  @chunk_sessions_on 100 # how many session keys must be process in one cypher query

  @stale_session_in 3600 * 1000 * 24 * 7 # 7 days

  @doc """
  Finds sessions which are expired for `@stale_session_in` milliseconds and excludes them
  from corresponding transitions. Then the sessions get removed. After this operation
  some transitions can have 0 count. It means they are useless, hence, they get removed
  by this method as well. After removing sessions and transitions, there can be lonely
  pages (pages without linked relations), those pages get removed too.
  """
  def clean_up do
    Db.Session.all_stale(@stale_session_in)
    |> Enum.chunk(@chunk_sessions_on, @chunk_sessions_on, [])
    |> Enum.each(fn(keys) -> Db.Transition.exclude_sessions(keys) end)

    Db.Session.remove_stale(@stale_session_in)
    Db.Transition.remove_idle
    Db.Page.remove_lonely
  end
end
