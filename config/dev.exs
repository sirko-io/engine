use Mix.Config

config :sirko, :scheduler,
  expire_sessions_every: 600 * 1000, # 10 minute
  remove_stale_data_every: 3600 * 1000 # 1 hr
