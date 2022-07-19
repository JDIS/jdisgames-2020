defmodule DiepIOWeb.PageController do
  use DiepIOWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", game_params: DiepIO.GameParamsRepository.get_game_params("main_game"))
  end

  def spectate(conn, %{"game_name" => game_name} = _params) do
    render(conn, "spectate.html", game_name: game_name)
  end

  def scoreboard(conn, _params) do
    render(conn, "scoreboard.html")
  end
end
