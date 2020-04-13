defmodule Diep.Io.Core.Upgrade do
  @moduledoc false

  @speed_rate 1.15
  @max_hp_rate 1.15
  @projectile_damage_rate 1.15
  @body_damage_rate 1.15
  @fire_rate_rate 0.85
  @hp_regen_rate 1.15

  def rates do
    %{
      speed: @speed_rate,
      max_hp: @max_hp_rate,
      projectile_damage: @projectile_damage_rate,
      body_damage: @body_damage_rate,
      fire_rate: @fire_rate_rate,
      hp_regen: @hp_regen_rate
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
end
