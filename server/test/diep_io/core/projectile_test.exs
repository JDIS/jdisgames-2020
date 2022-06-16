defmodule ProjectileTest do
  use ExUnit.Case, async: true

  alias DiepIO.Core.{Position, Projectile}

  @owner_id 1
  @damage 10
  @time_to_live 30

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
             time_to_live: _
           } = projectile

    assert radius == Projectile.default_radius()
    assert speed == Projectile.default_speed()
  end

  test "new/5 assigns opts values" do
    assert %Projectile{time_to_live: 0} = create_projectile(time_to_live: 0)
  end

  test "is_dead?/1 returns true if projectile's time_to_live <= 0" do
    [time_to_live: 0]
    |> create_projectile()
    |> Projectile.is_dead?()
    |> assert()
  end

  test "is_dead?/1 returns false if projectile's time_to_live > 0" do
    [time_to_live: 1]
    |> create_projectile()
    |> Projectile.is_dead?()
    |> Kernel.!()
    |> assert()
  end

  defp create_projectile(opts \\ []) do
    Projectile.new(@owner_id, Position.new(), Position.new(), @damage, @time_to_live, opts)
  end
end
