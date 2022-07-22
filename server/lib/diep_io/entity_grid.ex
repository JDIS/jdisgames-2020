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

    entity_left_edge = entity_x - entity_radius
    entity_top_edge = entity_y - entity_radius
    entity_right_edge = entity_x + entity_radius
    entity_bottom_edge = entity_y + entity_radius

    low_tile_x = floor(entity_left_edge / tile_size)
    low_tile_y = floor(entity_top_edge / tile_size)
    high_tile_x = floor(entity_right_edge / tile_size)
    high_tile_y = floor(entity_bottom_edge / tile_size)

    entity_tiles =
      for tile_x <- low_tile_x..high_tile_x//1,
          tile_y <- low_tile_y..high_tile_y//1 do
        {tile_x, tile_y}
      end

    tiles_map = Enum.reduce(entity_tiles, tiles_map, &insert_entity(&2, &1, head))

    build_tiles_map(rest, tile_size, tiles_map)
  end

  @spec insert_entity(t(), tile_coordinates, Entity.t()) :: t()
  defp insert_entity(tiles_map, coords, entity) do
    Map.update(tiles_map, coords, MapSet.new([entity]), &MapSet.put(&1, entity))
  end
end
