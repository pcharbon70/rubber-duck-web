import Config
config :rubberduck_web, token_signing_secret: "gKPMG+bbRJ/oKMjASPSIpJXsMkq6XpmG"
config :bcrypt_elixir, log_rounds: 1
config :ash, policies: [show_policy_breakdowns?: true]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rubberduck_web, RubberduckWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7WRgDb6LW3ACb+Md/WrTXeP/e/xYSg7Jy8eUWFwuqe+Q622TicVl5FKqYZAmgrDQ",
  server: false

# In test we don't send emails
config :rubberduck_web, RubberduckWeb.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
