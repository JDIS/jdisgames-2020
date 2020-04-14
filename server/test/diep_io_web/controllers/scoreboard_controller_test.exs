defmodule Diep.IoWeb.ScoreboardControllerTest do
  use Diep.IoWeb.ConnCase
  alias Diep.Io.ScoreRepository
  alias Diep.Io.UsersRepository

  @user %{name: "some_name"}

  test "GET /api/scoreboard", %{conn: conn} do
    {:ok, %{id: id}} = UsersRepository.create_user(@user)

    {:ok, original_score} = ScoreRepository.add_score(%{game_id: 2, score: 666, user_id: id})

    conn = get(conn, Routes.scoreboard_path(conn, :index))
    %{"scores" => [score]} = json_response(conn, 200)
    assert Map.get(score, "game_id") == 2
    assert Map.get(score, "user_id") == id
    assert Map.get(score, "score") == 666
    {:ok, left_datetime, _} = DateTime.from_iso8601(Map.get(score, "inserted_at") <> "Z")
    {:ok, right_datetime} = DateTime.from_naive(original_score.inserted_at, "Etc/UTC")
    assert left_datetime == right_datetime
  end
end
