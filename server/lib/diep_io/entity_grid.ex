defmodule DiepIO.EntityGrid do
  @moduledoc """
  An EntityGrid is a tiled representation of a game map.

  # Types

  t:
      The base reprensentation of an EntityGrid.

      EntityGrids are represented by maps in which the keys are the tile coordinates (from 0 to number_of_tiles - 1, both in x and y directions).
      The values are the MapSet of entities that are contained at least partially in the corresponding tile.

      If an Entity overlaps more than one tile, it will be added to the lists of all the tiles it overlaps.

  # Functions

  new:
      Builds an EntityGrid from a list of Entities. Returns EntityGrid.t().

      The resulting EntityGrid is not pre-initialized, meaning that any tile that does not contain any entity will *not* be present in the EntityGrid.
      All entities received in the input list are guaranteed to be in the EntityGrid.
  """

  alias DiepIO.Core.Entity

  @type tile_coordinates :: {integer(), integer()}
  @type t :: %{tile_coordinates => MapSet.t(Entity.t())}

  @spec new([Entity.t()], integer()) :: t()
  def new(entities, tile_size), do: build_tiles_map(entities, tile_size)

  @spec get_entities_for_tile(t(), tile_coordinates) :: MapSet.t(Entity.t())
  def get_entities_for_tile(grid, coords), do: Map.get(grid, coords)

  @spec build_tiles_map([Entity.t()], integer(), t()) :: t()
  defp build_tiles_map(entities, tile_size, tiles_map \\ %{})

  defp build_tiles_map([], _tile_size, tiles_map), do: tiles_map

  defp build_tiles_map([head | rest], tile_size, tiles_map) do
    {entity_x, entity_y} = Entity.get_position(head)
    entity_radius = Entity.get_radius(head)
    base_x = div(entity_x, tile_size)
    base_y = div(entity_y, tile_size)

    up_condition = entity_y - entity_radius <= base_y * tile_size
    down_condition = entity_y + entity_radius >= (base_y + 1) * tile_size
    left_condition = entity_x - entity_radius <= base_x * tile_size
    right_condition = entity_x + entity_radius >= (base_x + 1) * tile_size

    neighbour_checks = [
      {true, {base_x, base_y}},
      {up_condition, {base_x, base_y - 1}},
      {down_condition, {base_x, base_y - 1}},
      {left_condition, {base_x - 1, base_y}},
      {right_condition, {base_x + 1, base_y}},
      {up_condition and left_condition, {base_x - 1, base_y - 1}},
      {up_condition and right_condition, {base_x + 1, base_y - 1}},
      {down_condition and left_condition, {base_x - 1, base_y - 1}},
      {down_condition and right_condition, {base_x + 1, base_y - 1}}
    ]

    tiles_map =
      neighbour_checks
      |> Enum.filter(fn {is_in_tile, _} -> is_in_tile end)
      |> Enum.map(fn {_cond, coords} -> coords end)
      |> Enum.reduce(tiles_map, &insert_entity(&2, &1, head))

    build_tiles_map(rest, tile_size, tiles_map)
  end

  @spec insert_entity(t(), tile_coordinates, Entity.t()) :: t()
  defp insert_entity(tiles_map, coords, entity) do
    Map.update(tiles_map, coords, MapSet.new([entity]), &MapSet.put(&1, entity))
  end
end
