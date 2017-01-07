use Mix.Config

config :sirko, :scheduler,
  expire_sessions_in: 600 * 1000, # 10 minute
  remove_stale_data_in: 3600 * 1000 # 1 hr
