use Mix.Config

# Depending on the defined log level, all errors and info messages
# get outputted to the console. If a rollbar access token is provided,
# errors will be tracked by http://rollbar.com as well.
config :logger, backends: [:console, Rollbax.Logger]

config :logger, Rollbax.Logger, level: :error
