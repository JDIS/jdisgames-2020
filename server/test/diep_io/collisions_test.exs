defmodule CollisionsTest do
  use ExUnit.Case

  alias Diep.Io.Collisions
  alias Diep.Io.Core.{Entity, Tank}

  setup do
    origin_tank = Tank.new(1, "origin_tank") |> Tank.move({0, 0})
    tank2 = Tank.new(2, "tank2")

    [origin_tank: origin_tank, tank2: tank2]
  end

  test "calculate_collisions/2 returns a map of colliding entities", %{origin_tank: origin_tank} do
    expected_result = MapSet.new([{origin_tank, origin_tank}])

    assert Collisions.calculate_collisions([origin_tank], [origin_tank]) == expected_result
  end

  test "calculate_collisions/2 does not return a collision for entities exactly 2 radiuses apart", %{
    origin_tank: origin_tank,
    tank2: tank2
  } do
    tank_radius = Entity.get_radius(origin_tank)
    tank2 = Tank.move(tank2, {tank_radius * 2, 0})

    expected_result = MapSet.new()

    assert Collisions.calculate_collisions([origin_tank], [tank2]) == expected_result
  end

  test "calculate_collisions/2 returns a collision for entities more than 2 radiuses apart", %{
    origin_tank: origin_tank,
    tank2: tank2
  } do
    tank_radius = Entity.get_radius(origin_tank)
    tank2 = Tank.move(tank2, {tank_radius * 2 + 1, 0})

    expected_result = MapSet.new()

    assert Collisions.calculate_collisions([origin_tank], [tank2]) == expected_result
  end
end
