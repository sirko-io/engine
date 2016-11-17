use Mix.Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

config :sirko, :web,
  client_url: System.get_env("SIRKO_CLIENT_URL") # define this variable in your .bashrc

config :sirko, :scheduler,
  timeout: 60 * 1000 # 1 minute
