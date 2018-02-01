defmodule Sirko.Web.Predictor do
  @moduledoc """
  Makes a prediction by using the current path supplied
  in the request parameters.
  """

  require Logger

  alias Sirko.Predictor

  def call(_conn, params) do
    current_path = params["current"]

    next_page = Predictor.predict(current_path, confidence_threshold())

    log_prediction(current_path, next_page)

    build_body(next_page)
  end

  defp log_prediction(current_path, nil) do
    Logger.info(fn -> "No prediction for #{current_path}" end)
  end

  defp log_prediction(current_path, next_page) do
    Logger.info(fn -> "Predicted #{next_page.path} for #{current_path}" end)
  end

  defp build_body(nil), do: "{}"

  defp build_body(next_page) do
    Poison.encode!(%{path: next_page.path, assets: next_page.assets})
  end

  defp confidence_threshold do
    :sirko
    |> Application.get_env(:engine)
    |> Keyword.fetch!(:confidence_threshold)
  end
end
