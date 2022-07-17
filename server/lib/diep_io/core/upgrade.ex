defmodule DiepIO.Core.Upgrade do
  @moduledoc false

  @upgrade_descriptions %{
    speed: {:integer, 0.3},
    max_hp: {:integer, 0.3},
    projectile_damage: {:integer, 0.3},
    body_damage: {:integer, 0.3},
    fire_rate: {:float, -0.15},
    hp_regen: {:float, 0.3},
    projectile_time_to_live: {:integer, 0.1}
  }

  @type upgradable_stat ::
          :speed | :max_hp | :projectile_damage | :body_damage | :fire_rate | :hp_regen | :projectile_time_to_live
  @type upgrade_rates :: %{
          speed: float(),
          max_hp: float(),
          projectile_damage: float(),
          body_damage: float(),
          fire_rate: float(),
          hp_regen: float(),
          projectile_time_to_live: float()
        }

  @spec calculate_stat_value(upgradable_stat(), number(), integer()) :: number()
  def calculate_stat_value(stat, base_value, level) do
    {stat_type, upgrade_rate} = @upgrade_descriptions[stat]

    cast_value =
      case stat_type do
        :integer -> &floor/1
        :float -> &Float.round(&1, 2)
      end

    raw_value = base_value + base_value * upgrade_rate * level

    raw_value
    |> max(0.0)
    |> cast_value.()
  end

  @spec rates() :: upgrade_rates()
  def rates do
    Map.new(@upgrade_descriptions, fn {stat, {_, upgrade_rate}} -> {stat, upgrade_rate} end)
  end

  @spec upgradable_stats :: MapSet.t(upgradable_stat())
  def upgradable_stats,
    do:
      MapSet.new([
        :speed,
        :max_hp,
        :projectile_damage,
        :body_damage,
        :fire_rate,
        :hp_regen,
        :projectile_time_to_live
      ])
end
