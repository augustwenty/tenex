import Config

# Configure tenex
config :tenex,
  reserved_tenants: [
    "www",
    "api",
    "admin",
    "security",
    "app",
    "staging",
    "tenex_test",
    "travis",
    ~r/^db\d+$/
  ]

# Configure your database
config :tenex, ecto_repos: [Tenex.PGTestRepo]

config :tenex, Tenex.PGTestRepo,
  username: System.get_env("PG_USERNAME") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  hostname: System.get_env("PG_HOST") || "localhost",
  database: "tenex_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
