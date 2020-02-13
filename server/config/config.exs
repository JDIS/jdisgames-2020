use Mix.Config

config :diep_io,
  namespace: Diep.Io,
  ecto_repos: [Diep.Io.Repo]

# Configures the endpoint
config :diep_io, Diep.IoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "g8VX25ZVsHysCHLvoZBcypPuUNZF3aw99FPB83G5cgLVVE6V+fiRuSFei9Tdk1rp",
  render_errors: [view: Diep.IoWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Diep.Io.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
