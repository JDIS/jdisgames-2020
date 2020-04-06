defmodule TankTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Position, Tank}
  alias Diep.Io.Helpers.Angle

  @tank_name "Tank"
  @tank_id 1

  setup do
    [tank: Tank.new(@tank_id, @tank_name)]
  end

  test "new/1 creates a tank", %{tank: tank} do
    assert %Tank{
             id: @tank_id,
             name: @tank_name,
             current_hp: current_hp,
             max_hp: max_hp,
             speed: speed,
             upgrade_levels: %{max_hp: 0, speed: 0, fire_rate: 0, projectile_damage: 0, body_damage: 0},
             fire_rate: fire_rate,
             projectile_damage: projectile_damage,
             body_damage: body_damage,
             cooldown: 0,
             experience: 0,
             upgrade_tokens: 0,
             position: {_, _}
           } = tank

    assert current_hp == Tank.default_hp()
    assert max_hp == Tank.default_hp()
    assert speed == Tank.default_speed()
    assert fire_rate == Tank.default_fire_rate()
    assert projectile_damage == Tank.default_projectile_damage()
    assert body_damage == Tank.default_body_damage()
  end

  test "hit/2 damages the given tank", %{tank: tank} do
    assert Tank.hit(tank, 10).current_hp == Tank.default_hp() - 10
  end

  test "heal/2 restores the given tank's hp", %{tank: tank} do
    healed_tank =
      tank
      |> Tank.hit(10)
      |> Tank.heal(10)

    assert healed_tank.current_hp == Tank.default_hp()
  end

  test "heal/2 does not overheal the given tank", %{tank: tank} do
    assert Tank.heal(tank, 10).current_hp == Tank.default_hp()
  end

  test "add_experience/2 increases the given tank's xp", %{tank: tank} do
    assert Tank.add_experience(tank, 10).experience == 10
  end

  test "add_experience/2 gives upgrade tokens", %{tank: tank} do
    experienced_tank = Tank.add_experience(tank, 10)

    assert experienced_tank.upgrade_tokens > tank.upgrade_tokens
  end

  test "add_exprience/2 does not give spent tokens back", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_experience(10)
      |> Tank.buy_max_hp_upgrade()
      |> Tank.add_experience(5)

    assert upgraded_tank.upgrade_tokens == 0
  end

  test "is_alive?/1 determines if the given tank is alive", %{tank: tank} do
    assert Tank.is_alive?(tank)
  end

  test "is_dead?/1 determines if the given tank is dead", %{tank: tank} do
    dead_tank = Tank.hit(tank, tank.current_hp)
    assert Tank.is_dead?(dead_tank)
  end

  test "buy_upgrade/2 applies an upgrade to the given tank", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_max_hp_upgrade()

    assert upgraded_tank.upgrade_levels[:max_hp] == tank.upgrade_levels[:max_hp] + 1
    assert upgraded_tank.upgrade_tokens == 0
  end

  test "buy_upgrade/2 without enough experience does not apply the upgrade", %{tank: tank} do
    non_upgraded_tank = Tank.buy_max_hp_upgrade(tank)

    assert non_upgraded_tank == tank
  end

  test "move/2 changes the tank's position", %{tank: tank} do
    new_position = {42, 69}
    assert Tank.move(tank, new_position).position == new_position
  end

  test "increase_score/2 increases the score by the specified amount", %{tank: tank} do
    score = (tank |> Tank.increase_score(65) |> Tank.increase_score(4)).score
    assert score == 69
  end

  test "set_cooldown/1 sets the tank's cooldown", %{tank: tank} do
    on_cooldown_tank = Tank.set_cooldown(tank)

    assert on_cooldown_tank.cooldown == tank.fire_rate
  end

  test "set_cannon_angle/2 sets the tank's cannon_angle", %{tank: tank} do
    position = Position.random()
    new_angle = Tank.set_cannon_angle(tank, position).cannon_angle
    assert new_angle == Angle.degree(tank.position, position)
  end

  test "shoot/2 updates the tank and creates a projectile", %{tank: tank} do
    position = Position.random()

    {updated_tank, projectile} = Tank.shoot(tank, position)

    assert updated_tank.cooldown != tank.cooldown
    assert projectile.damage == tank.projectile_damage
    assert projectile.position == tank.position
  end

  test "shoot/2 does not shoot on cooldown", %{tank: tank} do
    assert {tank, nil} =
             tank
             |> Tank.set_cooldown()
             |> Tank.shoot(Position.random())
  end

  test "buy_max_hp_upgrade/1 increases tank's max hp", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_max_hp_upgrade()

    assert upgraded_tank.max_hp > tank.max_hp
  end

  test "buy_speed_upgrade/1 increases tank's speed", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_speed_upgrade()

    assert upgraded_tank.speed > tank.speed
  end

  test "buy_projectile_damage_upgrade/1 increases tank's projectile damage", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_projectile_damage_upgrade()

    assert upgraded_tank.projectile_damage > tank.projectile_damage
  end

  test "buy_fire_rate_upgrade/1 increases tank's fire rate", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_fire_rate_upgrade()

    assert upgraded_tank.fire_rate < tank.fire_rate
  end

  test "buy_fire_rate_upgrade does not decrease fire_rate below 0", %{tank: tank} do
    upgraded_tank =
      %{tank | fire_rate: 0}
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_fire_rate_upgrade()

    assert upgraded_tank.fire_rate == 0
  end

  test "buy_body_damage_upgrade/1 increases tank's body damage", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_body_damage_upgrade()

    assert upgraded_tank.body_damage > tank.body_damage
  end
end
