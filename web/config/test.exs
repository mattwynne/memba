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

# Strongly consistent projectors can hold independent SQL sandbox ownership
# connections, even when the BEAM is constrained to one online scheduler.
repo_pool_size = max(System.schedulers_online() * 2, 16)

repo_pool_config =
  if System.get_env("PHX_SERVER") == "true" do
    [pool_size: repo_pool_size]
  else
    [pool: Ecto.Adapters.SQL.Sandbox, pool_size: repo_pool_size]
  end

config :memba,
       Memba.Repo,
       [
         username: System.get_env("PGUSER") || System.get_env("USER"),
         port: String.to_integer(System.get_env("PGPORT") || "5432"),
         database: "memba_test#{System.get_env("MIX_TEST_PARTITION")}"
       ] ++ repo_pool_config ++ repo_connection_config

event_store_config =
  [
    serializer: Commanded.Serialization.JsonSerializer,
    username: System.get_env("PGUSER") || System.get_env("USER"),
    port: String.to_integer(System.get_env("PGPORT") || "5432"),
    database: "memba_test#{System.get_env("MIX_TEST_PARTITION")}",
    schema: "event_store",
    pool_size: System.schedulers_online() * 2
  ] ++ repo_connection_config

config :memba, Memba.EventStore, event_store_config
config :memba, Memba.Messaging.EventStore, event_store_config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :memba, MembaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  check_origin: ["//localhost", "//lvh.me", "//*.lvh.me"],
  secret_key_base: "+oZn9i13kWVdYNGOEgsHq8mRThfrIm6gsdUyl5gUMJXV8sHSGJ7m0sDaknZ7eOWQ",
  server: false

config :memba, :session_cookie_domain, ".lvh.me"

# In ordinary ExUnit tests we don't send emails. Browser acceptance tests opt into
# Swoosh's local adapter so they can inspect `/dev/mailbox` like a developer would.
config :memba, dev_routes: true

if System.get_env("MEMBA_ACCEPTANCE_LOCAL_EMAIL") == "true" do
  config :memba, :messaging_email_delivery_provider, Memba.Messaging.EmailDeliveryProviders.Local

  config :memba, Memba.Mailer,
    adapter: Swoosh.Adapters.Local,
    api_key: "acceptance-local-mailbox"

  config :memba, Memba.Accounts.AuthEmail,
    from: "auth@mail.memba.local",
    message_stream: "acceptance-auth"
else
  config :memba, Memba.Mailer, adapter: Swoosh.Adapters.Test
end

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# The supervised dispatcher stays running in tests so supervision wiring is
# covered, but focused tests opt into DB-backed claiming with their own
# sandbox-shared dispatcher process.
config :memba, :email_delivery_dispatcher_dispatch_enabled, false

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

config :memba, :club_site,
  base_domain: "lvh.me",
  scheme: "http",
  port: String.to_integer(System.get_env("PORT") || "4002")

config :cucumber,
  features: ["../acceptance-tests/features/**/*.feature"],
  steps: ["test/features/step_definitions/**/*.exs"],
  tags: "not @not-domain and not @todo-domain"
