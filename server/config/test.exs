import Config

# Configure your database
config :diep_io, Diep.Io.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "diep_io_test"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :diep_io, Diep.IoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SAbAiqwr0oXoUWJrXM4EVtgvHlZCZGhmrd201YMloxIydSZCWqMvmx5TFMQ982i4",
  server: false

# Print nothing during tests
config :logger, backends: []

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
