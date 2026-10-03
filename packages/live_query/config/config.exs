import Config

config :live_query, LiveQuery.TestEndpoint,
  secret_key_base: String.duplicate("live-query-test-secret-", 4),
  live_view: [signing_salt: "live-query-test"],
  server: false
