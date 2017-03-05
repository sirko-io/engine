use Mix.Config

config :bolt_sips, Bolt,
  url: "localhost:7688"

config :sirko, :web,
  port: 4001,
  client_url: "http://app.io"

config :logger, :console,
  level: :error
