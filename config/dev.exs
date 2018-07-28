use Mix.Config

config :sirko, :scheduler,
  # 10 minute
  expire_sessions_every: 600 * 1000,
  # 1 hr
  remove_stale_data_every: 3600 * 1000

config :sirko, :engine,
  max_pages_in_prediction: 4,
  confidence_threshold: 0.1
