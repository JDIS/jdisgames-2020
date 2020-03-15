defmodule Diep.Io.Collisions do
  @moduledoc """
  Module for calculating collisions between two lists of entities.

  This module does not use any message passing and is perfectly pure.
  """

  alias Diep.Io.Core.{Entity, Position}
  alias Diep.Io.EntityGrid

  @default_tile_size 100

  @type collision_set_t :: MapSet.t({Entity.t(), Entity.t()})

  @spec calculate_collisions([Entity.t()], [Entity.t()]) :: collision_set_t()
  def calculate_collisions(entities, colliders) do
    entities_grid = EntityGrid.new(entities, @default_tile_size)
    colliders_grid = EntityGrid.new(colliders, @default_tile_size)

    calculate_collisions_from_grids(entities_grid, colliders_grid)
  end

  @spec calculate_collisions_from_grids(EntityGrid.t(), EntityGrid.t()) :: collision_set_t()
  defp calculate_collisions_from_grids(entities_grid, colliders_grid) do
    for {coords, entities} <- entities_grid,
        colliders = EntityGrid.get_entities_for_tile(colliders_grid, coords) do
      for entity <- entities,
          collider <- colliders,
          are_colliding?(entity, collider) do
        {entity, collider}
      end
    end
    |> List.flatten()
    |> MapSet.new()
  end

  @spec are_colliding?(Entity.t(), Entity.t()) :: boolean()
  defp are_colliding?(entity1, entity2) do
    distance = Position.distance(Entity.get_position(entity1), Entity.get_position(entity2))
    sum_radii = Entity.get_radius(entity1) + Entity.get_radius(entity2)
    distance < sum_radii
  end
end
