import Config

# Load env vars from .env files
env_file_name = ".env.#{Config.config_env()}"

if File.exists?(env_file_name) do
  DotenvParser.load_file(env_file_name)
end

# Configure Repo
if config_env() == :prod do
  config :diep_io, DiepIO.Repo, pool_size: DiepIOConfig.database_pool_size()
end

config :diep_io, DiepIO.Repo, url: DiepIOConfig.database_url()

# Configure Endpoint
if config_env() == :prod do
  config :diep_io, DiepIOWeb.Endpoint,
    server: true,
    url: [host: "example.com", port: 443],
    cache_static_manifest: "priv/static/cache_manifest.json",
    http: [
      ip: {0, 0, 0, 0},
      port: DiepIOConfig.port()
    ],
    secret_key_base: DiepIOConfig.secret_key_base()
end

# Configure DiepIO
if config_env() == :prod do
  config :diep_io,
    admin_username: DiepIOConfig.admin_username(),
    admin_password: DiepIOConfig.admin_password()
else
  config :diep_io, admin_username: "admin", admin_password: "admin"
end
