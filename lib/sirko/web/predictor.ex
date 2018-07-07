defmodule Sirko.Web.Predictor do
  @moduledoc """
  Makes a prediction by using the current path supplied in the request parameters.
  The prediction is returned as a JSON-encoded string.
  """

  require Logger

  alias Sirko.Predictor

  @spec call(conn :: Plug.Conn.t(), params :: map) :: String.t()
  def call(_, params) do
    current_path = params["current"]

    list =
      Predictor.predict(
        current_path,
        max_pages_in_prediction(),
        confidence_threshold()
      )

    log_prediction(current_path, list)

    Poison.encode!(build_body(list))
  end

  defp log_prediction(current_path, []) do
    Logger.info(fn -> "No prediction for #{current_path}" end)
  end

  defp log_prediction(current_path, list) do
    Logger.info(fn ->
      paths =
        list
        |> Enum.map(fn page -> page["path"] end)
        |> Enum.join(", ")

      "Predicted #{paths} for #{current_path}"
    end)
  end

  defp build_body(list) do
    page_attrs = ["path", "confidence"]

    {pages, assets} =
      Enum.reduce(list, {[], []}, fn page, {pages, assets} ->
        pages = [Map.take(page, page_attrs) | pages]
        assets = assets ++ page["assets"]

        {pages, assets}
      end)

    %{
      pages: pages,
      assets: Enum.uniq(assets)
    }
  end

  defp max_pages_in_prediction, do: get_config(:max_pages_in_prediction)

  defp confidence_threshold, do: get_config(:confidence_threshold)

  defp get_config(name) do
    :sirko
    |> Application.get_env(:engine)
    |> Keyword.fetch!(name)
  end
end
