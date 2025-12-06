import Config

config :scorebreak,
  ecto_repos: [ScoreBreak.Persistence.Repo]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
