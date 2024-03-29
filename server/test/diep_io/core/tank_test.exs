defmodule TankTest do
  use ExUnit.Case, async: true

  alias DiepIO.Core.{Position, Tank}
  alias DiepIO.GameParams
  alias DiepIO.Helpers.Angle

  @tank_name "Tank"
  @tank_id 1

  setup do
    [
      tank: Tank.new(@tank_id, @tank_name, GameParams.default_params().upgrade_params)
    ]
  end

  test "new/1 creates a tank", %{tank: tank} do
    default_upgrade_params = GameParams.default_params().upgrade_params

    assert %Tank{
             id: @tank_id,
             name: @tank_name,
             current_hp: current_hp,
             max_hp: max_hp,
             speed: speed,
             upgrade_levels: %{
               max_hp: 0,
               speed: 0,
               fire_rate: 0,
               projectile_damage: 0,
               body_damage: 0
             },
             fire_rate: fire_rate,
             projectile_damage: projectile_damage,
             body_damage: body_damage,
             cooldown: 0,
             experience: 0,
             upgrade_tokens: 0,
             position: {_, _},
             target: nil,
             destination: nil,
             upgrade_params: ^default_upgrade_params,
             ticks_alive: 0
           } = tank

    assert current_hp == default_upgrade_params.max_hp.base_value
    assert max_hp == default_upgrade_params.max_hp.base_value
    assert speed == default_upgrade_params.speed.base_value
    assert fire_rate == default_upgrade_params.fire_rate.base_value
    assert projectile_damage == default_upgrade_params.projectile_damage.base_value
    assert body_damage == default_upgrade_params.body_damage.base_value
  end

  test "hit/2 damages the given tank", %{tank: tank} do
    assert Tank.hit(tank, 10).current_hp == GameParams.default_params().upgrade_params.max_hp.base_value - 10
  end

  test "heal/2 restores the given tank's hp", %{tank: tank} do
    healed_tank =
      tank
      |> Tank.hit(10)
      |> Tank.heal(10)

    assert healed_tank.current_hp == GameParams.default_params().upgrade_params.max_hp.base_value
  end

  test "heal/2 does not overheal the given tank", %{tank: tank} do
    assert Tank.heal(tank, 10).current_hp == GameParams.default_params().upgrade_params.max_hp.base_value
  end

  test "add_experience/2 increases the given tank's xp", %{tank: tank} do
    assert Tank.add_experience(tank, 10).experience == 10
  end

  test "add_experience/2 gives upgrade tokens", %{tank: tank} do
    experienced_tank = Tank.add_experience(tank, 10)

    assert experienced_tank.upgrade_tokens > tank.upgrade_tokens
  end

  test "add_experience/2 doesn't give extra upgrade tokens (non-regression test)", %{tank: tank} do
    experienced_tank_1 = Tank.add_experience(tank, 10_000)
    experienced_tank_2 = Tank.add_experience(experienced_tank_1, 0)

    assert experienced_tank_1.upgrade_tokens == experienced_tank_2.upgrade_tokens
  end

  test "add_exprience/2 does not give spent tokens back", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_experience(2)
      |> Tank.buy_max_hp_upgrade()
      |> Tank.add_experience(2)

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

  test "shoot/1 updates the tank and creates a projectile", %{tank: tank} do
    tank =
      tank
      |> Tank.set_target(Position.random())

    {updated_tank, [projectile]} = Tank.shoot(tank)

    assert updated_tank.cooldown != tank.cooldown
    assert projectile.damage == tank.projectile_damage
    assert projectile.position == tank.position
  end

  test "shoot/1 creates a projectile with the proper time to live", %{tank: tank} do
    tank =
      tank
      |> Tank.set_target(Position.random())
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_projectile_time_to_live_upgrade()

    {_, [projectile]} = Tank.shoot(tank)

    assert projectile.time_to_live > GameParams.default_params().upgrade_params.projectile_time_to_live.base_value
  end

  test "shoot/1 creates three projectiles if the tank has the upgrade", %{} do
    tank =
      Tank.new(@tank_id, @tank_name, GameParams.default_params().upgrade_params)
      |> Tank.add_triple_gun()
      |> Tank.set_target(Position.random())

    {_, projectiles} = Tank.shoot(tank)

    assert length(projectiles) == 3
  end

  test "shoot/1 does not shoot on cooldown", %{tank: tank} do
    tank =
      tank
      |> Tank.set_target(Position.random())

    assert {_, []} =
             tank
             |> Tank.set_cooldown()
             |> Tank.shoot()
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

  test "buy_fire_rate_upgrade decreases fire_rate in a non-linear fashion", %{tank: tank} do
    upgraded_tank_1 =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_fire_rate_upgrade()

    upgraded_tank_2 =
      upgraded_tank_1
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_fire_rate_upgrade()

    assert tank.fire_rate - upgraded_tank_1.fire_rate != upgraded_tank_1.fire_rate - upgraded_tank_2.fire_rate
  end

  test "buy_fire_rate_upgrade does not decrease fire_rate below 0", %{tank: tank} do
    upgraded_tank =
      Enum.reduce(0..1000//1, tank, fn _, tank ->
        tank
        |> Tank.add_upgrade_tokens(1)
        |> Tank.buy_fire_rate_upgrade()
      end)

    assert upgraded_tank.fire_rate >= 0
  end

  test "buy_body_damage_upgrade/1 increases tank's body damage", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_body_damage_upgrade()

    assert upgraded_tank.body_damage > tank.body_damage
  end

  test "buy_hp_regen_upgrade/1 increases tank's hp_regen", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_hp_regen_upgrade()

    assert upgraded_tank.hp_regen > tank.hp_regen
  end

  test "buy_projectile_time_to_live_upgrade/1 inscreases the tank's projectile_time_to_live", %{tank: tank} do
    upgraded_tank =
      tank
      |> Tank.add_upgrade_tokens(1)
      |> Tank.buy_projectile_time_to_live_upgrade()

    assert upgraded_tank.projectile_time_to_live > tank.projectile_time_to_live
  end

  test "mark_as_dead/1 sets the has_died attribute to true", %{tank: tank} do
    assert Tank.mark_as_dead(tank).has_died == true
  end

  test "mark_as_alive/1 sets the has_died attribute to false", %{tank: tank} do
    assert Tank.mark_as_alive(tank).has_died == false
  end

  test "set_destination/2 sets the desired destination", %{tank: tank} do
    expected_destination = Position.new(33, 33)

    new_tank =
      tank
      |> Tank.set_destination(expected_destination)

    assert new_tank.destination == expected_destination
  end

  test "set_target/2 sets the desired target", %{tank: tank} do
    expected_target = Position.new(33, 33)

    new_tank =
      tank
      |> Tank.set_target(expected_target)

    assert new_tank.target == expected_target
  end

  test "respawn/1 creates a new tank with the same name and ID", %{tank: tank} do
    respawned = Tank.respawn(tank)

    assert %{Tank.new(tank.id, tank.name, tank.upgrade_params) | position: respawned.position} == respawned
    assert respawned.position != tank.position
  end

  test "respawn/1 sets ticks_alive to 0", %{tank: tank} do
    old_tank = Tank.increase_ticks_alive(tank, 50)
    respawned = Tank.respawn(old_tank)

    assert respawned.ticks_alive == 0
  end

  test "increase_ticks_alive/2 increases a tank's ticks_alive property", %{tank: tank} do
    new_tank = Tank.increase_ticks_alive(tank, 50)

    assert new_tank.ticks_alive == tank.ticks_alive + 50
  end
end
