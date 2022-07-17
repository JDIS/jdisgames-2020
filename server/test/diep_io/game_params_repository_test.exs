defmodule DiepIO.GameParamsRepositoryTest do
  use DiepIO.DataCase

  alias DiepIO.GameParams
  alias DiepIO.GameParamsRepository
  alias DiepIO.Repo
  alias DiepIO.UpgradeParams
  alias DiepIOSchemas.GameParamsSchema
  alias DiepIOSchemas.UpgradeParamsSchema

  describe "game params repository" do
    test "get_game_params/1 returns the params for the given game" do
      game_name = "my test game"
      params = setup_stored_params(game_name)

      assert GameParamsRepository.get_game_params(game_name) == params
    end

    test "save_game_params/5 inserts the parameters" do
      game_name = "my test game"
      expected_game_params = game_params_fixture()

      GameParamsRepository.save_game_params(
        game_name,
        %GameParams{
          number_of_ticks: expected_game_params.number_of_ticks,
          max_debris_count: expected_game_params.max_debris_count,
          max_debris_generation_rate: expected_game_params.max_debris_generation_rate,
          score_multiplier: expected_game_params.score_multiplier,
          upgrade_params: %{
            speed: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            max_hp: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            projectile_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            body_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            fire_rate: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            hp_regen: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
            projectile_time_to_live: %UpgradeParams{base_value: 10, upgrade_rate: 0.5}
          }
        }
      )

      [fetched_params] = Repo.all(GameParamsSchema)

      assert fetched_params.game_name == game_name
      assert fetched_params.number_of_ticks == expected_game_params.number_of_ticks
      assert fetched_params.max_debris_count == expected_game_params.max_debris_count
      assert fetched_params.max_debris_generation_rate == expected_game_params.max_debris_generation_rate
      assert fetched_params.score_multiplier == expected_game_params.score_multiplier
    end
  end

  @spec game_params_fixture :: GameParams.t()
  defp game_params_fixture do
    %GameParams{
      max_debris_count: 10,
      max_debris_generation_rate: 0.5,
      score_multiplier: 1.0,
      number_of_ticks: 10,
      upgrade_params: %{
        speed: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        max_hp: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        projectile_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        body_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        fire_rate: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        hp_regen: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
        projectile_time_to_live: %UpgradeParams{base_value: 10, upgrade_rate: 0.5}
      }
    }
  end

  @spec setup_stored_params(String.t()) :: GameParams.t()
  defp setup_stored_params(game_name) do
    game_params = game_params_fixture()

    schema = %GameParamsSchema{
      game_name: game_name,
      max_debris_count: game_params.max_debris_count,
      max_debris_generation_rate: game_params.max_debris_generation_rate,
      score_multiplier: game_params.score_multiplier,
      number_of_ticks: game_params.number_of_ticks,
      upgrade_params: %{
        speed: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.speed.base_value,
          upgrade_rate: game_params.upgrade_params.speed.upgrade_rate
        },
        max_hp: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.max_hp.base_value,
          upgrade_rate: game_params.upgrade_params.max_hp.upgrade_rate
        },
        projectile_damage: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.projectile_damage.base_value,
          upgrade_rate: game_params.upgrade_params.projectile_damage.upgrade_rate
        },
        body_damage: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.body_damage.base_value,
          upgrade_rate: game_params.upgrade_params.body_damage.upgrade_rate
        },
        fire_rate: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.fire_rate.base_value,
          upgrade_rate: game_params.upgrade_params.fire_rate.upgrade_rate
        },
        hp_regen: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.hp_regen.base_value,
          upgrade_rate: game_params.upgrade_params.hp_regen.upgrade_rate
        },
        projectile_time_to_live: %UpgradeParamsSchema{
          base_value: game_params.upgrade_params.projectile_time_to_live.base_value,
          upgrade_rate: game_params.upgrade_params.projectile_time_to_live.upgrade_rate
        }
      }
    }

    Repo.insert!(schema)

    game_params
  end
end
