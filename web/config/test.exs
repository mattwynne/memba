import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
pg_host = System.get_env("PGHOST") || "localhost"

repo_connection_config =
  if String.starts_with?(pg_host, "/") do
    [socket_dir: pg_host]
  else
    [hostname: pg_host]
  end

config :memba,
       Memba.Repo,
       [
         username: System.get_env("PGUSER") || System.get_env("USER"),
         port: String.to_integer(System.get_env("PGPORT") || "5432"),
         database: "memba_test#{System.get_env("MIX_TEST_PARTITION")}",
         pool: Ecto.Adapters.SQL.Sandbox,
         pool_size: System.schedulers_online() * 2
       ] ++ repo_connection_config

config :memba,
       Memba.EventStore,
       [
         serializer: Commanded.Serialization.JsonSerializer,
         username: System.get_env("PGUSER") || System.get_env("USER"),
         port: String.to_integer(System.get_env("PGPORT") || "5432"),
         database: "memba_test#{System.get_env("MIX_TEST_PARTITION")}",
         schema: "event_store",
         pool_size: System.schedulers_online() * 2
       ] ++ repo_connection_config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :memba, MembaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+oZn9i13kWVdYNGOEgsHq8mRThfrIm6gsdUyl5gUMJXV8sHSGJ7m0sDaknZ7eOWQ",
  server: false

# In test we don't send emails
config :memba, Memba.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :cucumber,
  features: ["../acceptance-tests/features/**/*.feature"],
  steps: ["test/features/step_definitions/**/*.exs"]
