defmodule Diep.IoWeb.PageController do
  use Diep.IoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def spectate(conn, _params) do
    render(conn, "spectate.html")
  end

  def scoreboard(conn, _params) do
    render(conn, "scoreboard.html")
  end
end
