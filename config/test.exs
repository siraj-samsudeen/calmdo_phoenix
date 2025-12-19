import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :calmdo_phoenix, CalmdoPhoenix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "calmdo_phoenix_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :calmdo_phoenix, CalmdoPhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "b+cT4THVBBJ0pWprQS3Kd5ATCuDsYa2zl1OKvBG9tQOGNOyUlMjsWkrbjjomNdwE",
  server: false

# In test we don't send emails
config :calmdo_phoenix, CalmdoPhoenix.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :phoenix_test, :endpoint, CalmdoPhoenixWeb.Endpoint
