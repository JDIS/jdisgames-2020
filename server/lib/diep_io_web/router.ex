defmodule Diep.IoWeb.Router do
  use Diep.IoWeb, :router
  alias Diep.IoWeb.Authentication

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :basic_auth do
    plug BasicAuth,
      callback: &Authentication.authenticate/3
  end

  scope "/", Diep.IoWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/spectate", PageController, :spectate
    get "/scoreboard", PageController, :scoreboard
  end

  # Other scopes may use custom stacks.
  scope "/api", Diep.IoWeb do
    pipe_through :api

    resources "/scoreboard", ScoreboardController, only: [:index]
  end

  scope "/admin", Diep.IoWeb do
    pipe_through [:browser, :basic_auth]

    get "/", AdminController, :index

    get "/start", AdminController, :start_game
    get "/stop", AdminController, :stop_game
    get "/kill", AdminController, :kill_game
  end

  scope "/team-registration", Diep.IoWeb do
    pipe_through :browser

    get "/", TeamRegistrationController, :new
    post "/register", TeamRegistrationController, :create
  end
end
