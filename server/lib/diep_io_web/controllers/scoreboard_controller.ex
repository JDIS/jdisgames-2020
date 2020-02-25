defmodule Diep.IoWeb.ScoreboardController do
  use Diep.IoWeb, :controller
  alias Diep.Io.ScoreRepository

  def index(conn, _params) do
    scores = ScoreRepository.get_scores()
    render(conn, "scoreboard.json", %{scores: scores})
  end
end
