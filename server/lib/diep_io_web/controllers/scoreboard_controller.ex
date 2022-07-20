defmodule DiepIOWeb.ScoreboardController do
  use DiepIOWeb, :controller
  alias DiepIO.ScoreRepository

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    scores = Enum.map(ScoreRepository.get_scores(), &encode_score/1)
    render(conn, "scoreboard.json", %{scores: scores})
  end

  defp encode_score(score) do
    %{
      game_id: score.game_id,
      score: score.score,
      inserted_at: score.inserted_at,
      user_id: score.user.id,
      user_name: score.user.name
    }
  end
end
