import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :diep_io, Diep.Io.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :diep_io, Diep.IoWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT", "4000"))],
  secret_key_base: secret_key_base,
  server: true
