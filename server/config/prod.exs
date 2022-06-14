import Config

# Do not print debug messages in production
config :logger, level: :info

config :diep_io, DiepIOWeb.Endpoint,
  force_ssl: [
    hsts: true,
    rewrite_on: [:x_forwarded_proto],
    exclude: ["localhost"]
  ]
