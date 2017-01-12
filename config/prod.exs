use Mix.Config

# Depending on the defined log level, all errors and info messages
# get outputted to the console. If a rollbar access token is provided,
# errors will be tracked by http://rollbar.com as well.
config :logger,
  backends: [:console, Rollbax.Logger]

config :logger, Rollbax.Logger,
  level: :error

rollbar_access_token = System.get_env("ROLLBAR_ACCESS_TOKEN")

config :rollbax,
  access_token: rollbar_access_token,
  enabled: rollbar_access_token != nil && rollbar_access_token != ""
