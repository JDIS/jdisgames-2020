use Mix.Config

config :diep_io, Diep.IoWeb.Endpoint,
  # force_ssl: [hsts: true],
  url: [host: "localhost", port: 80],
  # https: [
  #   :inet6,
  #   port: 443,
  #   cipher_suite: :strong,
  #   keyfile: System.get_env("SSL_KEY_PATH"),
  #   certfile: System.get_env("SSL_CERT_PATH")
  # ],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info
