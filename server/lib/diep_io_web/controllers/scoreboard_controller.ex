defmodule DiepIOWeb.ScoreboardController do
  use DiepIOWeb, :controller
  alias DiepIO.ScoreRepository

  def index(conn, _params) do
    scores = ScoreRepository.get_scores()
    render(conn, "scoreboard.json", %{scores: scores})
  end
end
