use Mix.Config

config :bolt_sips, Bolt, url: "localhost:7688"

config :sirko, :web,
  port: 4001,
  client_url: "http://app.io"

config :sirko, :engine, max_pages_in_prediction: 2

config :logger, :console, level: :error
