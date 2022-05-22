defmodule DiepIOWeb.ScoreboardController do
  use DiepIOWeb, :controller
  alias DiepIO.ScoreRepository

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    scores = Enum.map(ScoreRepository.get_scores(), &encode_score/1)
    render(conn, "scoreboard.json", %{scores: scores})
  end

  defp encode_score(score) do
    {encoded, _} = Map.split(score, ~W(game_id score user_id inserted_at)a)
    encoded
  end
end
