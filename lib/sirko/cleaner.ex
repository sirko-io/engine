defmodule Sirko.Cleaner do
  @moduledoc """
  Takes care of removing needless and harmful data.
  """

  alias Sirko.Db

  # how many session keys must be processed in one cypher query
  @chunk_sessions_on 100

  @doc """
  Finds sessions which are expired for `stale_session_in` milliseconds and excludes them
  from corresponding transitions. Then the sessions get removed. After this operation
  some transitions can have 0 count. It means they are useless, hence, they get removed
  by this method as well. After removing sessions and transitions, there can be lonely
  pages (pages without linked relations), those pages get removed too.
  """
  @spec clean_up(stale_session_in :: integer) :: any
  def clean_up(stale_session_in) do
    # TODO: do we need to do this operation in a transaction?
    stale_session_in
    |> Db.Session.all_stale()
    |> Enum.chunk(@chunk_sessions_on, @chunk_sessions_on, [])
    |> Enum.each(fn keys -> Db.Transition.exclude_sessions(keys) end)

    Db.Session.remove_stale(stale_session_in)
    Db.Transition.remove_idle()
    Db.Page.remove_lonely()
  end
end
