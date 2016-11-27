use Mix.Config

config :neo4j_sips, Neo4j,
  url: "http://localhost:7484"

config :sirko, :web,
  port: 4001,
  client_url: "http://test.localhost:3000"

config :logger, :console,
  level: :error
