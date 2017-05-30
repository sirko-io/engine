defmodule Sirko.Web.Predictor do
  @moduledoc """
  Makes a prediction by using the current path supplied
  in the request parameters.
  """

  require Logger

  import Plug.Conn

  alias Sirko.Predictor

  def call(conn) do
    current_path = conn.query_params["cur"]

    next_path = Predictor.predict(current_path, confidence_threshold()) || ""

    log_prediction(current_path, next_path)

    conn |> send_resp(200, next_path)
  end

  defp log_prediction(current_path, "") do
    Logger.info fn -> "No prediction for #{current_path}" end
  end

  defp log_prediction(current_path, next_path) do
    Logger.info fn -> "Predicted #{next_path} for #{current_path}" end
  end

  defp confidence_threshold do
    :sirko
    |> Application.get_env(:engine)
    |> Keyword.fetch!(:confidence_threshold)
  end
end
