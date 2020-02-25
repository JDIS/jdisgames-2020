defmodule Diep.IoWeb.Router do
  use Diep.IoWeb, :router

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
end
