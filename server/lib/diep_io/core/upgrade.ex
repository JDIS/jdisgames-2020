defmodule DiepIO.Core.Upgrade do
  @moduledoc false

  alias DiepIO.GameParams

  @upgrade_types %{
    speed: :integer,
    max_hp: :integer,
    projectile_damage: :integer,
    body_damage: :integer,
    fire_rate: :float,
    hp_regen: :float,
    projectile_time_to_live: :integer
  }

  @type upgradable_stat ::
          :speed | :max_hp | :projectile_damage | :body_damage | :fire_rate | :hp_regen | :projectile_time_to_live

  @spec calculate_stat_value(upgradable_stat(), integer(), GameParams.upgrade_params()) :: number()
  def calculate_stat_value(stat, level, upgrade_params) do
    stat_type = @upgrade_types[stat]
    %{base_value: base_value, upgrade_rate: upgrade_rate} = upgrade_params[stat]

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
