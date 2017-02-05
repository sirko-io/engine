defmodule Sirko.Web.Predictor do
  @moduledoc """
  Makes a prediction by using the current path supplied
  in the request parameters.
  """

  require Logger

  import Plug.Conn
  import Sirko.Url, only: [ extract_path: 1 ]

  alias Sirko.Predictor

  def call(conn) do
    current_path = conn.query_params["cur"] |> extract_path

    next_path = Predictor.predict(current_path) || ""

    log_prediction(current_path, next_path)

    conn |> send_resp(200, next_path)
  end

  defp log_prediction(current_path, "") do
    Logger.info("No prediction for #{current_path}")
  end

  defp log_prediction(current_path, next_path) do
    Logger.info("Predicted #{next_path} for #{current_path}")
  end
end
