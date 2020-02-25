defmodule Diep.Io.ScoreRepositoryTest do
  use Diep.Io.DataCase

  alias Diep.Io.{ScoreRepository, UsersRepository}

  describe "scores" do
    alias Diep.Io.Users.Score

    @valid_attrs %{game_id: 42, score: 120, user_id: 41}
    @user %{name: "some_user"}
    @invalid_attrs %{game_id: nil, score: nil}
    @invalid_2_attrs %{game_id: 42, score: nil}

    def score_fixture(attrs \\ %{}) do
      {:ok, score} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ScoreRepository.add_score()

      score
    end

    setup do
      {:ok, user} = UsersRepository.create_user(@user)
      [user: user]
    end

    test "get_scores/0 returns all scores", %{user: user} do
      score = score_fixture(%{user_id: user.id})
      assert ScoreRepository.get_scores() == [score]
    end

    test "add_score/1 with valid data creates a score", %{user: user} do
      assert {:ok, %Score{} = score} =
               ScoreRepository.add_score(%{@valid_attrs | user_id: user.id})

      assert score.game_id == 42
      assert score.score == 120
    end

    test "add_score/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ScoreRepository.add_score(@invalid_attrs)
      assert {:error, %Ecto.Changeset{}} = ScoreRepository.add_score(@invalid_2_attrs)
    end
  end
end
