defmodule Sirko.Predictor do
  alias Sirko.Db, as: Db

  @doc """
  Returns the path to a next page if it meets the given confidence threshold.
  Otherwise, nil.
  """
  def predict(current_path, threshold) do
    Db.Transition.predict(current_path)
    |> calc_confidence
    |> check_confidence(threshold)
  end

  defp calc_confidence(nil), do: { nil, -1 }
  defp calc_confidence(info) do
    %{
      "path"  => path,
      "count" => count,
      "total" => total
    } = info

    { path, count / total }
  end

  defp check_confidence({ path, confidence }, threshold) when confidence >= threshold, do: path
  defp check_confidence(_, _), do: nil
end
