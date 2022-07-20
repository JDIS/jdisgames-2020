defmodule DiepIOWeb.Router do
  use DiepIOWeb, :router
  alias DiepIOWeb.AuthenticationPlug
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {DiepIOWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :basic_auth do
    plug(AuthenticationPlug)
  end

  scope "/", DiepIOWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/spectate", PageController, :spectate)
    get("/scoreboard", PageController, :scoreboard)
  end

  # Other scopes may use custom stacks.
  scope "/api", DiepIOWeb do
    pipe_through(:api)

    resources("/scoreboard", ScoreboardController, only: [:index])
  end

  scope "/admin", DiepIOWeb do
    pipe_through([:browser, :basic_auth])

    get("/", AdminController, :index)

    post("/start", AdminController, :start_game)
    post("/stop", AdminController, :stop_game)
    post("/kill", AdminController, :kill_game)
    post("/save", AdminController, :save_params)
  end

  scope "/team-registration", DiepIOWeb do
    pipe_through(:browser)

    get("/", TeamRegistrationController, :new)
    post("/register", TeamRegistrationController, :create)
  end

  scope "/dashboard" do
    pipe_through([:browser, :basic_auth])
    live_dashboard("/", metrics: DiepIOWeb.Telemetry)
  end
end
