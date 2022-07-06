defmodule DiepIO.GameParamsRepositoryTest do
  use DiepIO.DataCase

  alias DiepIO.GameParamsRepository
  alias DiepIO.Repo
  alias DiepIOSchemas.GameParams

  describe "game params repository" do
    test "get_game_params/1 returns the params for the given game" do
      game_name = "my test game"
      params = setup_stored_params(game_name)

      assert GameParamsRepository.get_game_params(game_name) == params
    end

    test "save_game_params/5 inserts the parameters" do
      game_name = "my test game"
      expected_game_params = game_params_fixture(game_name)

      GameParamsRepository.save_game_params(
        game_name,
        expected_game_params.number_of_ticks,
        expected_game_params.max_debris_count,
        expected_game_params.max_debris_generation_rate,
        expected_game_params.score_multiplier
      )

      [fetched_params] = Repo.all(GameParams)

      assert fetched_params.game_name == game_name
      assert fetched_params.number_of_ticks == expected_game_params.number_of_ticks
      assert fetched_params.max_debris_count == expected_game_params.max_debris_count
      assert fetched_params.max_debris_generation_rate == expected_game_params.max_debris_generation_rate
      assert fetched_params.score_multiplier == expected_game_params.score_multiplier
    end
  end

  @spec game_params_fixture(String.t()) :: GameParams.t()
  defp game_params_fixture(game_name) do
    %GameParams{
      game_name: game_name,
      max_debris_count: 10,
      max_debris_generation_rate: 0.5,
      score_multiplier: 1.0,
      number_of_ticks: 10
    }
  end

  @spec setup_stored_params(String.t()) :: GameParams.t()
  defp setup_stored_params(game_name) do
    game_name
    |> game_params_fixture()
    |> Repo.insert!()
  end
end
