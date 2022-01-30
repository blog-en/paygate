import Config

# Configures the endpoint
config :paygate, PaygateWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "m5RzT+LaGCub8Mh2HT3ZxEWiCIKgj98zll6axTMWW0YNgq/mnWTder5EX33NrLQe",
  render_errors: [view: PaygateWeb.ErrorView, accepts: ~w(json), layout: false],
  live_view: [signing_salt: "ypSiC67O"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :paygate, Throttler.RateLimiter, target_module: Throttler.RateLimitterConfig

config :paygate, Paygate.PromEx,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [:phoenix_channel_event_metrics],
  grafana: :disabled

config :paygate,
  ecto_repos: [Paygate.Infrastructure.Repo]

config :paygate, Paygate.Infrastructure.Repo,
  migration_timestamps: [type: :utc_datetime_usec],
  migration_primary_key: [name: :id, type: :binary_id],
  idle_interval: 25_000,
  after_connect: {MyXQL, :query!, ["SET session wait_timeout = 60"]}

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :tzdata, :autoupdate, :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
