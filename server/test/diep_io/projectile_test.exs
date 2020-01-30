defmodule ProjectileTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Projectile

  @damage 10
  @expected_projectile %Projectile{
    radius: Projectile.default_radius(),
    speed: Projectile.default_speed(),
    damage: @damage
  }

  setup do
    [projectile: Projectile.new(@damage)]
  end

  test "Can create a projectile", %{projectile: projectile} do
    assert projectile == @expected_projectile
  end
end
