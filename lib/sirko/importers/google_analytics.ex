defmodule Sirko.Importers.GoogleAnalytics do
  @moduledoc """
  Loads sessions tracked via Google Analytics into the DB.
  The expected structure is a list of rows of https://bit.ly/2K0fEGO.

  Example:
    [
      %{
        dimensions: [
          "/about",
          "/contact",
          "2018072914"
        ],
        metrics: [
          %{values: ["2"]}
        ]
      }
    ]

  The date-hour value get used in place of a session key. Currently, we don't care about uniqueness
  of users, it doesn't effect the prediction model. So, even if there were 10 unique users in a certain
  date-hour they will be treated as one session (GA groups them).
  """

  require Logger

  alias Sirko.Neo4j

  @date_hour_regexp ~r/(\d{4})(\d{2})(\d{2})(\d{2})/

  @doc """
  Divides given exported GA records to build bulk queries which create pages and sessions.
  Every bulk query might contain up to 100 sessions. After bulding bulk queries they get
  executed in parallel.

  To reduce deadlocks and speed up executions, 2 extra steps get applied:
   - records get sorted before processing, so queries have less "MERGE" statements
   - shuffles built queries, so queries related to same pages are less likely to be executed
     in parallel

  After executing queries, it returns a number of created sessions.
  """
  @spec import(records :: [map()]) :: non_neg_integer()
  def import(records) do
    records
    |> Enum.sort_by(fn row ->
      [referrer_path, current_path, _] = row["dimensions"]
      referrer_path <> current_path
    end)
    |> Enum.chunk_every(100)
    |> Task.async_stream(__MODULE__, :prepare_bulk_query, [], ordered: false)
    |> Enum.map(fn {:ok, query} -> query end)
    |> Enum.shuffle()
    |> Task.async_stream(__MODULE__, :execute_query, [], ordered: false, timeout: 15_000)
    |> Enum.reduce(0, fn {:ok, count}, total -> total + count end)
  end

  def prepare_bulk_query(chunk) do
    chunk
    |> collect_pages_and_sessions
    |> build_bulk_query
  end

  @doc """
  The biggest problem in executing concurrent queries is deadlock. Thus, when Neo4j returns an error,
  the given query gets executed again. If it doesn't succeed after N attempts, an error gets added to
  the log, but the import method still continues. Although, this behavior might result in losing some
  imported sessions.
  """
  @spec execute_query(query :: Sirko.Neo4j.query()) :: non_neg_integer()
  def execute_query(nil), do: 0
  def execute_query(query) do
    %{
      stats: %{
        "relationships-created" => count
      }
    } = Neo4j.query_with_retries(query)

    count
  rescue
    error in Neo4j.AttemptsExhaustedError ->
      Logger.error(error.message)
      0
  end

  # Gathers pages into a map and sessions into a list. It would be better to
  # use the same data structure for both entities, but the map contains references to
  # pages which are required to link pages and sessions. The map looks like this:
  #
  #     %{"/about" => "p12345678", "/home" => "p87654321"}
  #
  # The values are references which are used in creating sessions. The returned list contains
  # already prepared query for creating sessions.
  @spec collect_pages_and_sessions(chunk :: [map()]) :: {map(), [String.t()]}
  defp collect_pages_and_sessions(chunk) do
    Enum.reduce(chunk, {%{}, []}, fn row, {pages, session_queries} ->
      [referrer_path, current_path, date_hour] = row["dimensions"]

      if referrer_path == current_path do
        {pages, session_queries}
      else
        pages =
          pages
          |> Map.put_new_lazy(referrer_path, fn -> generate_page_ref() end)
          |> Map.put_new_lazy(current_path, fn -> generate_page_ref() end)

        # a count of visits
        count =
          row["metrics"]
          |> List.first()
          |> get_in(["values"])
          |> List.first()
          |> String.to_integer()

        referrer_ref = Map.get(pages, referrer_path)
        current_ref = Map.get(pages, current_path)

        query = build_session_query(referrer_ref, current_ref, count, date_hour)

        {pages, [query | session_queries]}
      end
    end)
  end

  # Builds a bulk query which creates pages (only if some are missing) and sessions.
  #
  # Returns nil, if the sessions structure is empty (it might happen if there were only refreshes),
  @spec build_bulk_query(args :: {map(), [String.t()]}) :: String.t()
  defp build_bulk_query({_, []}), do: nil

  defp build_bulk_query({pages, session_queries}) do
    page_queries =
      Enum.reduce(pages, "", fn {path, ref}, acc ->
        acc <> build_page_query(path, ref)
      end)

    page_queries <> "CREATE " <> Enum.join(session_queries, ", ")
  end

  defp build_session_query(referrer_ref, current_ref, count, date_hour) do
    occurred_at = date_hour_to_timestamp(date_hour)

    "(#{referrer_ref})-[:SESSION { key: '#{date_hour}', occurred_at: #{occurred_at}, count: #{
      count
    } }]->(#{current_ref})"
  end

  defp build_page_query(path, page_key) do
    "MERGE (#{page_key}:Page { path: '#{path}' }) "
  end

  defp generate_page_ref, do: "p#{:erlang.unique_integer() * -1}"

  defp date_hour_to_timestamp(date_hour) do
    [_, year, month, day, hour] = Regex.run(@date_hour_regexp, date_hour)

    %DateTime{
      year: year |> String.to_integer(),
      month: month |> String.to_integer(),
      day: day |> String.to_integer(),
      hour: hour |> String.to_integer(),
      minute: 0,
      second: 0,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }
    |> DateTime.to_unix(:millisecond)
  end
end
