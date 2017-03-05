# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :sirko, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:sirko, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :bolt_sips, Bolt,
  url: System.get_env("NEO4J_URL") || "bolt://localhost:7687",
  ssl: System.get_env("NEO4J_SSL") || false,
  pool_size: System.get_env("NEO4J_POOL_SIZE") || 20,
  max_overflow: System.get_env("NEO4J_MAX_OVERFLOW") || 10,
  timeout: System.get_env("NEO4J_TIMEOUT") || 15_000

config :sirko, :web,
  port: System.get_env("SIRKO_HTTP_PORT") || 4000,
  client_url: System.get_env("SIRKO_CLIENT_URL") # the address of a site for which predictions should be made

config :sirko, :scheduler,
  expire_sessions_in: 3600 * 1000, # how often the scheduler should be launched to expire inactive sessions
  remove_stale_data_in: 3600 * 1000 * 24 # how often the scheduler should be launched to remove stale data

config :logger, :console,
  level: (System.get_env("SIRKO_DEBUG_LEVEL") || "info") |> String.to_atom,
  format: "$date $time [$level] $metadata$message\n"

config :rollbax,
  environment: Mix.env |> Atom.to_string,
  access_token: "", # give it an empty string to avoid failures in the dev and test env
  enabled: false

import_config "#{Mix.env}.exs"
