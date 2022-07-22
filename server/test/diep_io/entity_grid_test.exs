defmodule EntityGridTest do
  use ExUnit.Case

  alias DiepIO.Core.HotZone
  alias DiepIO.Core.Position
  alias DiepIO.Core.Tank
  alias DiepIO.EntityGrid
  alias DiepIO.GameParams

  @tile_size 100

  setup do
    tank = Tank.new(1, "tank", GameParams.default_params().upgrade_params)

    [tank: tank]
  end

  test "new/2 returns a map of the list of entities per tile", %{tank: tank} do
    tank = Tank.move(tank, {50, 50})

    expected_result = %{
      {0, 0} => MapSet.new([tank]),
      {0, 1} => MapSet.new([tank]),
      {1, 0} => MapSet.new([tank]),
      {1, 1} => MapSet.new([tank])
    }

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

  test "new/2 returns a map with full coverage of entities bigger than a single tile" do
    hot_zone = HotZone.new(Position.new(0, 0))

    expected_grid =
      for x <- -2..2//1,
          y <- -2..2//1,
          into: %{} do
        {{x, y}, MapSet.new([hot_zone])}
      end

    tile_size = div(hot_zone.radius, 2)
    grid = EntityGrid.new([hot_zone], tile_size)

    assert grid == expected_grid
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
