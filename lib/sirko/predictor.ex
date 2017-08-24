defmodule Sirko.Predictor do
  alias Sirko.Db, as: Db

  @doc """
  Returns the path to a next page if it meets the given confidence threshold.
  Otherwise, nil.
  """
  def predict(current_path, threshold) do
    current_path
    |> Db.Transition.predict
    |> calc_confidence
    |> check_confidence(threshold)
  end

  defp calc_confidence(nil), do: {nil, -1}
  defp calc_confidence(info) do
    %{
      "path"   => path,
      "assets" => assets,
      "count"  => count,
      "total"  => total
    } = info

    {%{path: path, assets: assets}, count / total}
  end

  defp check_confidence({page, confidence}, threshold) when confidence >= threshold, do: page
  defp check_confidence(_, _), do: nil
end
