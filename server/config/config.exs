import Config

config :diep_io,
  ecto_repos: [Diep.Io.Repo]

# Configures the endpoint
config :diep_io, Diep.IoWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: Diep.IoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Diep.Io.PubSub,
  live_view: [signing_salt: "1MeJOTSEqr9E/VaL7SRcwkCFdR3z4kB7"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
