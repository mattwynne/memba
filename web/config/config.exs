# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :memba,
  ecto_repos: [Memba.Repo],
  event_stores: [Memba.EventStore],
  event_sourced_projection_tables: [
    :projection_versions,
    :membership_clubs,
    :membership_memberships,
    :membership_people,
    :messaging_messages,
    :messaging_recipient_deliveries
  ],
  generators: [timestamp_type: :utc_datetime]

config :memba, Memba.Membership.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.EventStore,
    event_store: Memba.EventStore
  ],
  pubsub: :local,
  registry: :local

config :memba, Memba.Messaging.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.EventStore,
    event_store: Memba.Messaging.EventStore
  ],
  pubsub: :local,
  registry: :local

config :memba, :messaging_delivery_provider, Memba.Messaging.DeliveryProviders.Fake

config :commanded_ecto_projections, schema_prefix: nil

# Configure the endpoint
config :memba, MembaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MembaWeb.ErrorHTML, json: MembaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Memba.PubSub,
  live_view: [signing_salt: "LbMu1Jpe"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :memba, Memba.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  memba: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  memba: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
