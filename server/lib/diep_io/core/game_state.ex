defmodule Diep.Io.Core.GameState do
  @moduledoc """
  Module that handles most of the game's business logic
  (handle player actions, debris generation, etc).
  """

  alias Diep.Io.Collisions
  alias Diep.Io.Core.{Action, Debris, Entity, GameMap, Position, Projectile, Tank}
  alias Diep.Io.Users.User
  alias :rand, as: Rand

  @max_debris_count 100
  @max_debris_generation_rate 0.5
  @debris_size_probability [:small, :small, :small, :medium, :medium, :large]
  @projectile_decay 2

  @derive {Jason.Encoder, except: [:in_progress, :last_time]}
  defstruct [
    :in_progress,
    :tanks,
    :debris,
    :last_time,
    :map_width,
    :map_height,
    :ticks,
    :max_ticks,
    projectiles: []
  ]

  @type t :: %__MODULE__{
          in_progress: boolean(),
          tanks: %{integer() => Tank.t()},
          debris: [Debris.t()],
          last_time: integer(),
          map_width: integer(),
          map_height: integer(),
          ticks: integer(),
          max_ticks: integer(),
          projectiles: [Projectile.t()]
        }

  @spec new([User.t()], integer()) :: t()
  def new(users, max_ticks) do
    %__MODULE__{
      in_progress: false,
      tanks: initialize_tanks(users),
      debris: initialize_debris(),
      last_time: 0,
      map_width: GameMap.width(),
      map_height: GameMap.height(),
      ticks: 1,
      max_ticks: max_ticks
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game_state), do: %{game_state | in_progress: true}

  @spec stop_game(t()) :: t()
  def stop_game(game_state), do: %{game_state | in_progress: false}

  @doc """
    Increase the tick count by one. If the new count is equal to the max number of ticks
    in a game, also stop the game.
  """
  @spec increase_ticks(t()) :: t()
  def increase_ticks(game_state) do
    updated_state = Map.put(game_state, :ticks, game_state.ticks + 1)
    max_ticks = updated_state.max_ticks

    case updated_state.ticks do
      x when x > max_ticks -> stop_game(updated_state)
      _ -> updated_state
    end
  end

  @spec decrease_cooldowns(t()) :: t()
  def decrease_cooldowns(game_state) do
    Map.update!(game_state, :tanks, fn tanks ->
      Map.new(tanks, fn {id, tank} ->
        {id, Tank.decrease_cooldown(tank)}
      end)
    end)
  end

  @spec handle_players([Action.t()], t()) :: t()
  def handle_players(actions, game_state) do
    Enum.reduce(actions, game_state, &handle_action/2)
  end

  @spec handle_debris(t()) :: t()
  def handle_debris(game_state) do
    game_state
    |> generate_debris
  end

  @spec handle_projectiles(t()) :: t()
  def handle_projectiles(game_state) do
    projectiles =
      game_state.projectiles
      |> Enum.map(&Projectile.remove_hp(&1, @projectile_decay))
      |> Enum.reject(&Projectile.is_dead?/1)
      |> Enum.map(&Projectile.move/1)

    %{game_state | projectiles: projectiles}
  end

  @spec handle_collisions(t()) :: t()
  def handle_collisions(game_state) do
    game_state
    |> handle_tank_tank_collisions()
    |> handle_tank_projectile_collisions()
    |> handle_tank_debris_collision()
    |> handle_projectile_debris_collision()
  end

  defp handle_action(action, game_state) do
    game_state
    |> handle_shoot(action)
    |> handle_movement(action)
  end

  defp handle_movement(game_state, %Action{destination: destination}) when destination == nil,
    do: game_state

  defp handle_movement(game_state, action) do
    Map.update!(game_state, :tanks, fn tanks ->
      Map.update!(tanks, action.tank_id, fn tank ->
        new_position = Position.next(tank.position, action.destination, tank.speed)
        Tank.move(tank, new_position)
      end)
    end)
  end

  defp handle_shoot(game_state, %Action{target: target}) when target == nil, do: game_state

  defp handle_shoot(game_state, action) do
    {tank, projectile} =
      game_state
      |> Map.get(:tanks)
      |> Map.get(action.tank_id)
      |> Tank.shoot(action.target)

    case projectile == nil do
      true ->
        game_state

      false ->
        game_state
        |> Map.update!(:projectiles, fn projectiles ->
          [projectile | projectiles]
        end)
        |> Map.update!(:tanks, fn tanks ->
          Map.put(tanks, action.tank_id, tank)
        end)
    end
  end

  defp handle_tank_tank_collisions(%{tanks: tanks_map} = game_state) do
    tanks = Map.values(tanks_map)

    collisions = Collisions.calculate_collisions(tanks, tanks)

    tanks_map =
      collisions
      |> Enum.reduce(tanks_map, fn {tank, other_tank}, acc ->
        Map.replace!(acc, tank.id, Tank.hit(tank, Entity.get_body_damage(other_tank)))
      end)

    %{game_state | tanks: tanks_map}
  end

  defp handle_tank_projectile_collisions(%{tanks: tanks_map, projectiles: projectiles} = game_state) do
    collisions =
      tanks_map
      |> Map.values()
      |> Collisions.calculate_collisions(projectiles)

    tanks_map =
      collisions
      |> Enum.filter(fn {tank, projectile} -> tank.id != projectile.owner_id end)
      |> Enum.reduce(tanks_map, fn {tank, projectile}, acc ->
        projectile_damage = Map.fetch!(acc, projectile.owner_id).projectile_damage
        Map.replace!(acc, tank.id, Tank.hit(tank, projectile_damage))
      end)

    projectiles =
      projectiles
      |> handle_projectiles_collision(Enum.map(collisions, fn {_, projectile} -> projectile end))

    %{game_state | tanks: tanks_map, projectiles: projectiles}
  end

  defp handle_tank_debris_collision(%{tanks: tanks_map, debris: debris} = game_state) do
    collisions =
      tanks_map
      |> Map.values()
      |> Collisions.calculate_collisions(debris)

    tanks_map =
      collisions
      |> Enum.reduce(tanks_map, fn {tank, _debris}, acc ->
        Map.replace!(acc, tank.id, Tank.hit(tank, Debris.default_body_damage()))
      end)

    debris = handle_debris_collisions(debris, collisions)

    %{game_state | tanks: tanks_map, debris: debris}
  end

  defp handle_projectile_debris_collision(%{debris: debris, projectiles: projectiles} = game_state) do
    collisions =
      projectiles
      |> Collisions.calculate_collisions(debris)

    debris = handle_debris_collisions(debris, collisions)

    projectiles =
      projectiles
      |> handle_projectiles_collision(Enum.map(collisions, fn {projectile, _} -> projectile end))

    %{game_state | debris: debris, projectiles: projectiles}
  end

  defp handle_debris_collisions(debris, collisions) do
    debris
    |> Enum.map(fn deb -> Enum.reduce(collisions, deb, &damage_debris_if_hit/2) end)
    |> Enum.filter(&Debris.is_alive?/1)
  end

  defp handle_projectiles_collision(projectiles, collided_projectiles) do
    projectiles
    |> MapSet.new()
    |> MapSet.difference(MapSet.new(collided_projectiles))
    |> MapSet.to_list()
  end

  defp damage_debris_if_hit({other_entity, collided_debris}, debris) do
    if debris == collided_debris do
      Debris.hit(debris, Entity.get_body_damage(other_entity))
    else
      debris
    end
  end

  defp generate_debris(game_state) do
    case @max_debris_count - Enum.count(game_state.debris) do
      0 ->
        game_state

      missing_count ->
        rate = Rand.uniform() * @max_debris_generation_rate
        debris_count = max(round(missing_count * rate), 1)
        new_debris = create_debris(debris_count)
        %{game_state | debris: Enum.concat(game_state.debris, new_debris)}
    end
  end

  defp create_debris(count) do
    for _ <- 1..count, do: Debris.new(Enum.random(@debris_size_probability))
  end

  defp initialize_tanks(users),
    do: users |> Map.new(fn user -> {user.id, Tank.new(user.id, user.name)} end)

  defp initialize_debris, do: create_debris(@max_debris_count)
end
