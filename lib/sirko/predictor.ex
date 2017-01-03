defmodule Sirko.Predictor do
  alias Sirko.Db, as: Db

  def predict(current_path) do
    Db.Transition.predict(current_path)
  end
end
