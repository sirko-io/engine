defmodule Sirko.Predictor do
  alias Sirko.Db, as: Db

  @doc """
  Nothing very interesting here now. Computation is done in the DB,
  but later there might be work for this module too.
  """
  defdelegate predict(current_path, max_pages \\ 1, confidence_threshold \\ 0), to: Db.Transition
end
