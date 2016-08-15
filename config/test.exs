use Mix.Config

level = if System.get_env("DEBUG") do
  :debug
else
  :error
end

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"

config :sirko, :web,
  port: 4001,
  client_url: "http://test.localhost:3000"
