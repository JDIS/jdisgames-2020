defmodule TankTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Tank
  alias Diep.Io.Upgrades.MaxHP

  @expected_tank %Tank{
    name: "Tank",
    current_hp: Tank.default_hp(),
    max_hp: Tank.default_hp(),
    speed: Tank.default_speed(),
    upgrades: Tank.default_upgrades(),
    experience: 0
  }

  setup do
    [tank: Tank.new(@expected_tank.name)]
  end

  test "new/1 creates a tank", %{tank: tank} do
    assert tank == @expected_tank
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

  test "is_alive?/1 determines if the given tank is alive", %{tank: tank} do
    assert Tank.is_alive?(tank)
  end

  test "is_dead?/1 determines if the given tank is dead", %{tank: tank} do
    dead_tank = Tank.hit(tank, tank.current_hp)
    assert Tank.is_dead?(dead_tank)
  end

  test "increment_max_hp/2 increments the given tank's max_hp", %{tank: tank} do
    boosted_tank = Tank.increment_max_hp(tank, 100)
    assert boosted_tank.max_hp == Tank.default_hp() + 100
    assert boosted_tank.current_hp == Tank.default_hp() + 100
  end

  test "buy_upgrade/2 applies an upgrade to the given tank", %{tank: tank} do
    upgrade_price = MaxHP.price(0)

    upgraded_tank =
      tank
      |> Tank.add_experience(upgrade_price)
      |> Tank.buy_upgrade(MaxHP)

    assert upgraded_tank.max_hp > tank.max_hp
    assert upgraded_tank.experience == 0
  end

  test "buy_upgrade/2 without enough experience does not apply the upgrade", %{tank: tank} do
    non_upgraded_tank = Tank.buy_upgrade(tank, MaxHP)

    assert non_upgraded_tank == tank
  end
end
