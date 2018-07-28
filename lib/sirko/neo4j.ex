defmodule Sirko.Neo4j do
  defmodule Error do
    defexception message: ""
  end

  defmodule AttemptsExhaustedError do
    defexception message: ""
  end

  @moduledoc """
  A simple wrapper for Neo4j to execute queries
  """

  require Logger

  alias Bolt.Sips, as: Bolt

  @type result :: [map] | Exception.t()
  @type query :: String.t()
  @type params :: map()

  @doc """
  Executes the given query and logs the duration of its execution.
  Raises an error if the query fails.
  """
  @spec query(query, params) :: result()
  def query(query, params \\ %{}) do
    {duration, query_res} = :timer.tc(Bolt, :query, [Bolt.pool_name(), query, params])

    Logger.info(fn ->
      "Neo4j query (#{time_in_msec(duration)}ms):\n#{query} Params: #{inspect(params)}"
    end)

    case query_res do
      {:ok, res} ->
        res

      {:error, details} ->
        code = Keyword.get(details, :code)
        message = Keyword.get(details, :message)

        Logger.error("#{code} #{message}\nQuery:\n#{query}")

        raise Error, message: message
    end
  end

  @doc """
  There are cases when a failed query has a chance to succeed, for example, after deadlock.
  So, this method tries to execute the given query N times. After exhausting all attempts,
  an error gets raised.
  """
  @spec query_with_retries(
          query,
          params,
          attempt :: non_neg_integer(),
          max_attempts :: pos_integer()
        ) :: result()
  def query_with_retries(query, params \\ %{}, attempt \\ 0, max_attempts \\ 5)

  def query_with_retries(query, _, attempt, max_attempts) when attempt == max_attempts do
    raise AttemptsExhaustedError,
      message: "There were several attempts to execute a query but they failed\nQuery:\n#{query}"
  end

  def query_with_retries(query, params, attempt, max_attempts) do
    query(query, params)
  rescue
    Error -> query_with_retries(query, params, attempt + 1, max_attempts)
  end

  defp time_in_msec(time_in_microsec) do
    (time_in_microsec / 1000)
    |> Float.round(1)
  end
end
