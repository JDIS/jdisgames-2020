defmodule CollisionsTest do
  use ExUnit.Case

  alias DiepIO.Collisions
  alias DiepIO.GameParams
  alias DiepIO.Core.{Entity, Tank}

  setup do
    origin_tank = Tank.new(1, "origin_tank", GameParams.default_params().upgrade_params) |> Tank.move({0, 0})

    [origin_tank: origin_tank]
  end

  test "calculate_collisions/2 returns a map of colliding entities", %{origin_tank: origin_tank} do
    tank2 = %{origin_tank | name: "tank2"}
    expected_result = MapSet.new([{origin_tank, tank2}])

    assert Collisions.calculate_collisions([origin_tank], [tank2]) == expected_result
  end

  test "calculate_collisions/2 returns no collision for entities exactly 2 radiuses apart", %{
    origin_tank: origin_tank
  } do
    tank_radius = Entity.get_radius(origin_tank)
    tank2 = Tank.move(origin_tank, {tank_radius * 2, 0})

    expected_result = MapSet.new()

    assert Collisions.calculate_collisions([origin_tank], [tank2]) == expected_result
  end

  test "calculate_collisions/2 returns no collision for entities more than 2 radiuses apart", %{
    origin_tank: origin_tank
  } do
    tank_radius = Entity.get_radius(origin_tank)
    tank2 = Tank.move(origin_tank, {tank_radius * 2 + 1, 0})

    expected_result = MapSet.new()

    assert Collisions.calculate_collisions([origin_tank], [tank2]) == expected_result
  end

  test "calculate_collisions/2 does not return a collisions between an Entity and itself", %{
    origin_tank: origin_tank
  } do
    assert Collisions.calculate_collisions([origin_tank], [origin_tank]) == MapSet.new()
  end
end
