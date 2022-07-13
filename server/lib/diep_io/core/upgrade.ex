defmodule DiepIO.Core.Upgrade do
  @moduledoc false

  @upgrade_descriptions %{
    speed: {:integer, 1.3},
    max_hp: {:integer, 1.3},
    projectile_damage: {:integer, 1.3},
    body_damage: {:integer, 1.3},
    fire_rate: {:float, 0.85},
    hp_regen: {:float, 1.3},
    projectile_time_to_live: {:integer, 1.1}
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

  @spec upgrade_stat(upgradable_stat(), number()) :: number()
  def upgrade_stat(stat, current_value) do
    case @upgrade_descriptions[stat] do
      {:integer, upgrade_rate} -> Kernel.floor(current_value * upgrade_rate)
      {:float, upgrade_rate} -> Float.round(current_value * upgrade_rate, 2)
    end
  end

  @spec rates() :: upgrade_rates()
  def rates do
    Map.new(@upgrade_descriptions, fn {stat, {_, upgrade_rate}} -> {stat, upgrade_rate} end)
  end
end
