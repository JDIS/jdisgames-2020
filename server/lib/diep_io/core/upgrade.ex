defmodule DiepIO.Core.Upgrade do
  @moduledoc false

  @speed_rate 1.3
  @max_hp_rate 1.3
  @projectile_damage_rate 1.3
  @body_damage_rate 1.3
  @fire_rate_rate 0.85
  @hp_regen_rate 1.3
  @projectile_time_to_live_rate 1.1

  @type upgrade_rates :: %{
          speed: float(),
          max_hp: float(),
          projectile_damage: float(),
          body_damage: float(),
          fire_rate: float(),
          hp_regen: float(),
          projectile_time_to_live: float()
        }

  @spec rates :: upgrade_rates()
  def rates do
    %{
      speed: @speed_rate,
      max_hp: @max_hp_rate,
      projectile_damage: @projectile_damage_rate,
      body_damage: @body_damage_rate,
      fire_rate: @fire_rate_rate,
      hp_regen: @hp_regen_rate,
      projectile_time_to_live: @projectile_time_to_live_rate
    }
  end

  @spec speed(integer) :: integer
  def speed(value), do: Kernel.floor(value * @speed_rate)

  @spec max_hp(integer) :: integer
  def max_hp(value), do: Kernel.floor(value * @max_hp_rate)

  @spec projectile_damage(integer) :: integer
  def projectile_damage(value), do: Kernel.floor(value * @projectile_damage_rate)

  @spec body_damage(integer) :: integer
  def body_damage(value), do: Kernel.floor(value * @body_damage_rate)

  @spec fire_rate(number) :: number
  def fire_rate(value), do: Float.round(value * @fire_rate_rate, 2)

  @spec hp_regen(number) :: number
  def hp_regen(value), do: Float.round(value * @hp_regen_rate, 2)

  @spec projectile_time_to_live(number) :: number
  def projectile_time_to_live(value), do: round(value * @projectile_time_to_live_rate)
end
