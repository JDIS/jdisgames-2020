defmodule TankTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Tank, as: Tank

  @expected_tank %Tank{
    name: "Tank",
    current_hp: Tank.default_hp(),
    max_hp: Tank.default_hp(),
    speed: Tank.default_speed(),
    experience: 0
  }

  setup do
    [tank: Tank.new(@expected_tank.name)]
  end

  test "Can create a tank", %{tank: tank} do
    assert tank == @expected_tank
  end

  test "Can lose hp", %{tank: tank} do
    assert Tank.hit(tank, 10).current_hp == Tank.default_hp() - 10
  end

  test "Can be healed", %{tank: tank} do
    healed_tank =
      tank
      |> Tank.hit(10)
      |> Tank.heal(10)

    assert healed_tank.current_hp == Tank.default_hp()
  end

  test "Can not be overhealed", %{tank: tank} do
    assert Tank.heal(tank, 10).current_hp == Tank.default_hp()
  end

  test "Can gain experience", %{tank: tank} do
    assert Tank.add_experience(tank, 10).experience == 10
  end

  test "Can be alive", %{tank: tank} do
    assert Tank.is_alive?(tank)
  end

  test "Can be dead", %{tank: tank} do
    dead_tank = Tank.hit(tank, tank.current_hp)
    assert Tank.is_dead?(dead_tank)
  end
end
