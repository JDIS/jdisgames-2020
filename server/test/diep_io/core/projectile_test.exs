defmodule ProjectileTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Position, Projectile}

  @owner_id 1
  @damage 10

  setup do
    [projectile: create_projectile()]
  end

  test "new/4 creates a projectile", %{projectile: projectile} do
    assert %Projectile{
             owner_id: @owner_id,
             radius: radius,
             speed: speed,
             damage: @damage,
             position: {_, _},
             angle: _,
             hp: hp
           } = projectile

    assert radius == Projectile.default_radius()
    assert speed == Projectile.default_speed()
    assert hp == Projectile.default_hp()
  end

  test "new/5 assigns opts values" do
    assert %Projectile{hp: 0} = create_projectile(hp: 0)
  end

  test "is_dead?/1 returns true if projectile's hp <= 0" do
    [hp: 0]
    |> create_projectile()
    |> Projectile.is_dead?()
    |> assert()
  end

  test "is_dead?/1 returns false if projectile's hp > 0" do
    [hp: 1]
    |> create_projectile()
    |> Projectile.is_dead?()
    |> Kernel.!()
    |> assert()
  end

  defp create_projectile(opts \\ []) do
    Projectile.new(@owner_id, Position.new(), Position.new(), @damage, opts)
  end
end
