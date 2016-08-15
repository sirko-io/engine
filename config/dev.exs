use Mix.Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

config :sirko, :web,
  client_url: "http://localhost:3000"

config :sirko, :scheduler,
  timeout: 60 * 1000 # 1 minute
