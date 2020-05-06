defmodule Diep.IoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :diep_io

  socket "/socket/spectate", Diep.IoWeb.SpectateSocket,
    websocket: [compress: true],
    longpoll: false

  socket "/socket/bot", Diep.IoWeb.BotSocket,
    websocket: [compress: true],
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  compress_assets =
    case System.get_env("MIX_ENV") do
      "prod" -> true
      _ -> false
    end

  plug Plug.Static,
    at: "/",
    from: :diep_io,
    gzip: compress_assets,
    only: ~w(css fonts images audio js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_diep_io_key",
    signing_salt: "Xxw/nVCe"

  plug Diep.IoWeb.Router
end
