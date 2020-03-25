defmodule Diep.Io.Core.Upgrade do
  @moduledoc false

  @speed_rate 1.15
  @max_hp_rate 1.15
  @projectile_damage_rate 1.15
  @body_damage_rate 1.15
  @fire_rate_rate 0.85

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
end
