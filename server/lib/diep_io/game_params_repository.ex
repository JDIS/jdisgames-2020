defmodule DiepIO.GameParamsRepository do
  @moduledoc """
  The GameParamsRepositoryContext
  """

  import Ecto.Changeset

  alias DiepIO.Core.Upgrade
  alias DiepIO.Repo

  alias DiepIO.GameParams
  alias DiepIO.UpgradeParams
  alias DiepIOSchemas.GameParamsSchema

  @spec get_game_params(String.t()) :: GameParams.t() | nil
  def get_game_params(game_name) do
    case Repo.get(GameParamsSchema, game_name) do
      nil ->
        nil

      schema ->
        %GameParams{
          max_debris_count: schema.max_debris_count,
          max_debris_generation_rate: schema.max_debris_generation_rate,
          score_multiplier: schema.score_multiplier,
          number_of_ticks: schema.number_of_ticks,
          upgrade_params: %{
            speed: %UpgradeParams{
              base_value: schema.upgrade_params.speed.base_value,
              upgrade_rate: schema.upgrade_params.speed.upgrade_rate
            },
            max_hp: %UpgradeParams{
              base_value: schema.upgrade_params.max_hp.base_value,
              upgrade_rate: schema.upgrade_params.max_hp.upgrade_rate
            },
            projectile_damage: %UpgradeParams{
              base_value: schema.upgrade_params.projectile_damage.base_value,
              upgrade_rate: schema.upgrade_params.projectile_damage.upgrade_rate
            },
            body_damage: %UpgradeParams{
              base_value: schema.upgrade_params.body_damage.base_value,
              upgrade_rate: schema.upgrade_params.body_damage.upgrade_rate
            },
            fire_rate: %UpgradeParams{
              base_value: schema.upgrade_params.fire_rate.base_value,
              upgrade_rate: schema.upgrade_params.fire_rate.upgrade_rate
            },
            hp_regen: %UpgradeParams{
              base_value: schema.upgrade_params.hp_regen.base_value,
              upgrade_rate: schema.upgrade_params.hp_regen.upgrade_rate
            },
            projectile_time_to_live: %UpgradeParams{
              base_value: schema.upgrade_params.projectile_time_to_live.base_value,
              upgrade_rate: schema.upgrade_params.projectile_time_to_live.upgrade_rate
            }
          }
        }
    end
  end

  @spec save_game_params(String.t(), GameParams.t()) :: :ok
  def save_game_params(
        game_name,
        game_params
      ) do
    %GameParamsSchema{}
    |> cast(
      %{
        game_name: game_name,
        number_of_ticks: game_params.number_of_ticks,
        max_debris_count: game_params.max_debris_count,
        max_debris_generation_rate: game_params.max_debris_generation_rate,
        score_multiplier: game_params.score_multiplier,
        upgrade_params: Map.new(game_params.upgrade_params, fn {stat, params} -> {stat, Map.from_struct(params)} end)
      },
      [:game_name, :number_of_ticks, :max_debris_count, :max_debris_generation_rate, :score_multiplier]
    )
    |> cast_embed(:upgrade_params, with: &game_upgrades_changeset/2)
    |> validate_required([
      :game_name,
      :number_of_ticks,
      :max_debris_count,
      :max_debris_generation_rate,
      :score_multiplier,
      :upgrade_params
    ])
    |> Repo.insert!(on_conflict: :replace_all, conflict_target: :game_name)

    :ok
  end

  defp game_upgrades_changeset(upgrades, params) do
    upgrades
    |> cast(params, [])
    |> then(fn changeset ->
      Enum.reduce(Upgrade.upgradable_stats(), changeset, &cast_upgrade_param/2)
    end)
    |> validate_required(MapSet.to_list(Upgrade.upgradable_stats()))
  end

  defp cast_upgrade_param(stat, changeset) do
    cast_embed(changeset, stat, with: &upgrade_params_changeset/2)
  end

  defp upgrade_params_changeset(upgrade_params, params) do
    upgrade_params
    |> cast(params, [:upgrade_rate, :base_value])
    |> validate_required([:upgrade_rate, :base_value])
  end
end
