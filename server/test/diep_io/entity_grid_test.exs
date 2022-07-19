defmodule EntityGridTest do
  use ExUnit.Case

  alias DiepIO.Core.Tank
  alias DiepIO.EntityGrid
  alias DiepIO.GameParams

  @tile_size 100

  setup do
    tank = Tank.new(1, "tank", GameParams.default_params().upgrade_params)

    [tank: tank]
  end

  test "new/2 returns a map of the list of entities per tile", %{tank: tank} do
    tank = Tank.move(tank, {div(@tile_size, 2), div(@tile_size, 2)})
    expected_result = %{{0, 0} => MapSet.new([tank])}

    assert EntityGrid.new([tank], @tile_size) == expected_result
  end

  test "new/2 returns a map with neighbour tiles when entities overlap", %{tank: tank} do
    tank = Tank.move(tank, {0, 0})

    expected_result = %{
      {-1, -1} => MapSet.new([tank]),
      {0, -1} => MapSet.new([tank]),
      {-1, 0} => MapSet.new([tank]),
      {0, 0} => MapSet.new([tank])
    }

    assert EntityGrid.new([tank], @tile_size) == expected_result
  end

  test "get_set_for_coords/2 returns the list of entities for the given tile coordinates", %{
    tank: tank
  } do
    coords = {0, 0}
    expected_result = MapSet.new([tank])

    grid = %{
      coords => expected_result
    }

    assert EntityGrid.get_entities_for_tile(grid, coords) == expected_result
  end
end
