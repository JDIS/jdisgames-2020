use Mix.Config

# Configure your database
config :diep_io, Diep.Io.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "diep_io_dev"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :diep_io, Diep.IoWeb.Endpoint,
  http: [port: 4000],
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    npm: [
      "run",
      "watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :diep_io, Diep.IoWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/diep_io_web/{live,views}/.*(ex)$",
      ~r"lib/diep_io_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console,
  format: "$time [$level] $metadata - $message\n",
  level: :debug,
  metadata: [:request_id],
  utc_log: true,
  sync_threshold: 100

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
