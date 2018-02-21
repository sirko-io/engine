@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. More information can be found here
https://github.com/bitwalker/conform.
"""
[
  extends: [],
  import: [],
  mappings: [
    "neo4j.url": [
      commented: false,
      datatype: :binary,
      default: "bolt://localhost:7687",
      doc: """
      A url to a Neo4j instance. The engine only works with a bolt protocol.
      To provide credentials, use this format: bolt://username:password@host:7687
      """,
      hidden: false,
      to: "bolt_sips.Elixir.Bolt.url"
    ],
    "neo4j.ssl": [
      commented: false,
      datatype: :boolean,
      default: false,
      doc: "Either to use a secure connection or not",
      hidden: false,
      to: "bolt_sips.Elixir.Bolt.ssl"
    ],
    "neo4j.pool_size": [
      commented: false,
      datatype: :integer,
      default: 20,
      doc: "Maximum pool size",
      hidden: false,
      to: "bolt_sips.Elixir.Bolt.pool_size"
    ],
    "neo4j.max_overflow": [
      commented: false,
      datatype: :integer,
      default: 10,
      doc: "Maximum number of backup workers created if the pool is empty",
      hidden: false,
      to: "bolt_sips.Elixir.Bolt.max_overflow"
    ],
    "neo4j.timeout": [
      commented: false,
      datatype: :integer,
      default: 15000,
      doc: "Connection timeout in milliseconds",
      hidden: false,
      to: "bolt_sips.Elixir.Bolt.timeout"
    ],
    "logger.level": [
      commented: false,
      datatype: :atom,
      default: :info,
      doc: "The log level. It accepts the following values: debug, info, warn, error.",
      hidden: false,
      to: "logger.console.level"
    ],
    "rollbax.access_token": [
      commented: false,
      datatype: :binary,
      doc: """
      An access token to http://rollbar.com. This service provides a great feature to track all errors
      happening in an application. So, you will be aware if something happens wrong without looking into
      log files. If you don't want to use it, comment this option out.
      """,
      hidden: false,
      to: "rollbax.access_token"
    ],
    "rollbax.enabled": [
      commented: false,
      datatype: :boolean,
      doc: "Enables the rollbar logger",
      hidden: true,
      to: "rollbax.enabled"
    ],
    "sirko.web.port": [
      commented: false,
      datatype: :integer,
      default: 4000,
      doc:
        "An HTTP port to be used by the HTTP server. This port must be used to communicate to the engine.",
      hidden: false,
      to: "sirko.web.port"
    ],
    "sirko.web.client_url": [
      commented: false,
      datatype: :binary,
      default: "http://localhost",
      doc: "A url of a client application to make predictions for.",
      hidden: false,
      to: "sirko.web.client_url"
    ],
    "sirko.engine.inactive_session_in": [
      commented: false,
      datatype: :integer,
      default: 60,
      doc: """
      Time in minutes when sessions without activity get treated as inactive.
      Inactive sessions get expired and the tracking gets stopped for them.
      If a user comes with an expired session, a new session gets started.
      """,
      hidden: true,
      to: "sirko.engine.inactive_session_in"
    ],
    "sirko.engine.stale_session_in": [
      commented: false,
      datatype: :integer,
      default: 7,
      doc: """
      Duration in days of keeping expired sessions in the DB. Expired sessions which
      live longer that this value get removed from the DB and gets excluded by the prediction model.
      You might need to increase this value, if your site don't get big traffic.
      A higher number will allow the engine to get enough data to make predictions.
      On the other hand, if the navigation of your site changes too often,
      it is recommended to keep a lower value in order to exclude noise which effect
      correctness of the prediction.
      """,
      hidden: false,
      to: "sirko.engine.stale_session_in"
    ],
    "sirko.engine.confidence_threshold": [
      commented: false,
      datatype: :float,
      default: 0.2,
      doc: """
      A threshold of confidence to be met in order to add the prerender hint. When it is set to 1,
      the prerender hint will only be added in case of 100% confidence that the current user will visit
      a predicted page.
      """,
      hidden: false,
      to: "sirko.engine.confidence_threshold"
    ],
    "sirko.engine.max_pages_in_prediction": [
      commented: false,
      datatype: :integer,
      default: 1,
      doc: """
      A max number of pages which will be predicted to a user, hence, a number of pages
      which will be prefetched. They still should pass the confidence verification.
      For example, if the confidence threshold is 0.5, only 2 pages might be returned,
      even though this option specifies 10. So, the confidence threshold should be
      considered while setting this option.
      """,
      hidden: false,
      to: "sirko.engine.max_pages_in_prediction"
    ]
  ],
  transforms: [
    "rollbax.enabled": fn conf ->
      [{_, access_token}] = Conform.Conf.get(conf, "rollbax.access_token")

      access_token != nil && access_token != ""
    end,
    "sirko.engine.inactive_session_in": fn conf ->
      [{_, time_in_mins}] = Conform.Conf.get(conf, "sirko.engine.inactive_session_in")

      # converts time to milliseconds
      time_in_mins * 60 * 1000
    end,
    "sirko.engine.stale_session_in": fn conf ->
      [{_, time_in_days}] = Conform.Conf.get(conf, "sirko.engine.stale_session_in")

      # converts time to milliseconds
      time_in_days * 24 * 60 * 60 * 1000
    end
  ],
  validators: []
]
