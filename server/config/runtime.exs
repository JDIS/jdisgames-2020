import Config

# Load env vars from .env files
env_file_name = ".env.#{Config.config_env()}"

if File.exists?(env_file_name) do
  DotenvParser.load_file(env_file_name)
end

# Configure Repo
if config_env() == :prod do
  config :diep_io, DiepIo.Repo, pool_size: DiepIoConfig.database_pool_size()
end

config :diep_io, Diep.Io.Repo, url: DiepIoConfig.database_url()

# Configure Endpoint
if config_env() == :prod do
  config :diep_io, DiepIoWeb.Endpoint,
    server: true,
    url: [host: "example.com", port: 443],
    cache_static_manifest: "priv/static/cache_manifest.json",
    https: [
      port: DiepIoConfig.port()
    ],
    check_origin: [
      "https://example.com"
    ],
    secret_key_base: DiepIoConfig.secret_key_base()
end

# Configure DiepIo
if config_env() == :prod do
  config :diep_io, admin_username: DiepIoConfig.admin_username(), admin_password: DiepIoConfig.admin_password()
else
  config :diep_io, admin_username: "admin", admin_password: "admin"
end

config :diep_io, custom_badges_location: DiepIoConfig.custom_badges_location()
