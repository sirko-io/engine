defmodule Mix.Tasks.Sirko.ImportGa do
  defmodule TaskArgsError do
    defexception message: ""
  end

  @moduledoc """
  Loads users' sessions from Google Analytics by using Reporting API https://bit.ly/2K0fEGO.

  Usage:

  in production:

      bin/sirko import_ga <client_id> <client_secret> <view_id>

  in development:

      mix sirko.import_ga <client_id> <client_secret> <view_id>
  """

  use Mix.Task

  @shortdoc "Imports users' sessions from Google Analytics"

  @ga_scope "https://www.googleapis.com/auth/analytics.readonly"
  @ga_endpoint "https://analyticsreporting.googleapis.com/v4/reports:batchGet"
  @ga_page_size 5000

  # Export 500,000 records at most
  @ga_requests_limit 100
  @ga_max_page_token (@ga_requests_limit * @ga_page_size) |> Integer.to_string()

  @args_example "1234.apps.googleusercontent.com aBcD 1234567"

  alias IO.ANSI
  alias OAuth2.{Client, Strategy}
  alias Sirko.{Db, Session}
  alias Sirko.Importers.GoogleAnalytics, as: GaImporter

  def run(args) do
    args
    |> parse_args
    |> execute
  rescue
    e in TaskArgsError -> print_msg(e.message, :warning)
  end

  @doc """
  Obtains access to Reporting API then imports sessions into the DB.
  """
  @spec execute(opts :: [client_id: String.t(), client_secret: String.t(), view_id: String.t()]) ::
          any()
  def execute(opts) do
    Logger.configure(level: :error)

    Application.ensure_all_started(:bolt_sips)
    Application.ensure_all_started(:oauth2)

    {:ok, bolt_pid} = Bolt.Sips.start_link(Application.get_env(:bolt_sips, Bolt))

    try do
      opts
      |> auth_client
      |> capture_auth_code
      |> exchange_auth_code
      |> build_query
      |> start_timer("Importing sessions...")
      |> request_records(&import_sessions/1)
      |> print_outcome("Imported sessions in ")

      start_timer("Building transitions...")
      |> expire_sessions
      |> print_outcome("Built transitions in ")

      print_summary()
    rescue
      e in OAuth2.Error -> print_msg(e.reason, :error)
    after
      Supervisor.stop(bolt_pid)
    end
  end

  defp instruction do
    """
    Please, provide credentials to your Google Analytics account as:

        bin/sirko import_ga <client_id> <client_secret> <view_id>

    Example:

        bin/sirko import_ga #{@args_example}
    """
  end

  defp parse_args([client_id, client_secret, view_id]) do
    [client_id: client_id, client_secret: client_secret, view_id: view_id]
  end

  defp parse_args(_) do
    raise TaskArgsError, instruction()
  end

  defp auth_client(opts) do
    client =
      Client.new(
        strategy: Strategy.AuthCode,
        client_id: Keyword.get(opts, :client_id),
        site: "https://accounts.google.com",
        authorize_url: "/o/oauth2/auth",
        token_url: "/o/oauth2/token",
        redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
      )

    {client, opts}
  end

  defp capture_auth_code({client, opts}) do
    promt =
      "Please, open this URL in the browser and grant access to your GA account:\n" <>
        Client.authorize_url!(client, scope: @ga_scope) <> "\nThe code you've got from Google:"

    code =
      promt
      |> IO.gets()
      |> String.trim()

    {client, code, opts}
  end

  defp exchange_auth_code({client, code, opts}) do
    client =
      Client.get_token!(
        client,
        code: code,
        client_secret: Keyword.get(opts, :client_secret)
      )

    {client, opts}
  end

  defp start_date do
    days_back =
      Application.get_env(:sirko, :engine)
      |> Keyword.get(:stale_session_in)
      |> div(3600 * 1000 * 24)

    Date.utc_today()
    |> Date.add(days_back * -1)
    |> Date.to_string()
  end

  defp end_date do
    Date.utc_today() |> Date.to_string()
  end

  # To get a list of supported dimensions and metrics visit
  # https://developers.google.com/analytics/devguides/reporting/core/dimsmets.
  #
  # There is a `ga:dateHour` field which is used to group records by hours (also
  # this field is used as a session key), thus, there will be 24 sessions per day at most.
  # Farther, it is possible to group records by days, this grouping will give the same
  # transitions, however, it would result in one session per day. Such session will have
  # lots of visited pages and just one exist. Thus, this grouping will hide real exists
  # which might be important for the prediction model.
  defp build_query({client, opts}) do
    query = %{
      view_id: Keyword.get(opts, :view_id),
      date_ranges: [
        %{
          start_date: start_date(),
          end_date: end_date()
        }
      ],
      order_bys: [
        %{
          field_name: "ga:dateHour",
          sortOrder: "DESCENDING"
        }
      ],
      dimensions: [
        %{
          name: "ga:previousPagePath"
        },
        %{
          name: "ga:pagePath"
        },
        %{
          name: "ga:dateHour"
        }
      ],
      dimension_filter_clauses: [
        %{
          filters: [
            %{
              dimension_name: "ga:previousPagePath",
              operator: "EXACT",
              not: true,
              expressions: ["(entrance)"]
            }
          ]
        }
      ],
      metrics: [
        %{
          expression: "ga:pageviews"
        }
      ],
      hide_totals: true,
      hide_value_ranges: true,
      page_size: @ga_page_size
    }

    {client, query}
  end

  defp start_timer(data, msg) do
    print_msg(msg)

    data
    |> Tuple.append([timer: current_time()])
  end

  defp start_timer(msg) do
    print_msg(msg)

    [timer: current_time()]
  end

  defp current_time, do: :os.system_time(:millisecond)

  defp request_records({client, query, opts}, import_fn, page_token \\ nil) do
    query = Map.put(query, :page_token, page_token)

    resp = Client.post!(client, @ga_endpoint, %{report_requests: [query]})

    report = resp.body["reports"] |> List.first()

    created_sessions = import_fn.(report)

    total = Keyword.get(opts, :sessions_count, 0) + created_sessions

    print_progress(total)

    opts = Keyword.put(opts, :sessions_count, total)

    case report["nextPageToken"] do
      next_page_token when next_page_token in [nil, @ga_max_page_token] ->
        IO.write("\n")
        opts

      next_page_token ->
        request_records({client, query, opts}, import_fn, next_page_token)
    end
  end

  defp import_sessions(report) do
    report["data"]["rows"]
    |> GaImporter.import()
  end

  defp print_outcome(opts, msg) do
    timer = Keyword.get(opts, :timer)
    duration = (current_time() - timer) / 1000

    metric =
      if duration < 60 do
        "#{duration} secs"
      else
        "#{Float.round(duration / 60, 2)} mins"
      end

    print_msg(msg <> metric, :success)
  end

  defp expire_sessions(opts) do
    Session.expire_all_inactive(1000)
    opts
  end

  defp print_summary do
    [%{"transitions_count" => transitions_count, "pages_count" => pages_count}] =
      Db.Info.overview()

    "Currently the engine knows about #{transitions_count} transitions and #{pages_count} pages"
    |> print_msg(:success)
  end

  defp print_msg(msg), do: IO.puts(msg)

  defp print_msg(msg, :success), do: IO.puts(ANSI.green() <> msg <> ANSI.default_color())

  defp print_msg(msg, :warning), do: IO.puts(ANSI.yellow() <> msg <> ANSI.default_color())

  defp print_msg(msg, :error), do: IO.puts(ANSI.red() <> msg <> ANSI.default_color())

  defp print_progress(count) do
    # replaces the previous output, thus, there is only one such line
    IO.write("\rCreated #{count} sessions")
  end
end
