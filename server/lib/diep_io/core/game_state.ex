defmodule Diep.Io.Core.GameState do
  @moduledoc """
  Module that handles most of the game's business logic
  (handle player actions, debris generation, etc).
  """

  alias Diep.Io.Collisions
  alias Diep.Io.Core.{Action, Clock, Debris, Entity, GameMap, Position, Projectile, Tank, Upgrade}
  alias Diep.Io.Users.User
  alias :rand, as: Rand

  @max_debris_count 400
  @max_debris_generation_rate 0.03
  @debris_size_probability [:small, :small, :small, :small, :medium, :medium, :large]
  @projectile_decay 1
  @experience_loss_rate 0.5
  @experience_score_ratio_on_kill 0.1

  @derive {Jason.Encoder, except: [:should_stop?, :monitor_performance]}
  defstruct [
    :name,
    :tanks,
    :map_width,
    :map_height,
    :upgrade_rates,
    :game_id,
    :debris,
    :is_ranked,
    :projectiles,
    :monitor_performance?,
    :clock,
    should_stop?: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          tanks: %{integer() => Tank.t()},
          debris: [Debris.t()],
          map_width: integer(),
          map_height: integer(),
          upgrade_rates: %{
            :body_damage => float(),
            :fire_rate => float(),
            :max_hp => float(),
            :projectile_damage => float(),
            :speed => float(),
            :hp_regen => float()
          },
          game_id: integer(),
          is_ranked: boolean(),
          projectiles: [Projectile.t()],
          monitor_performance?: boolean(),
          clock: Clock.t(),
          should_stop?: boolean()
        }

  @spec new(atom(), [User.t()], integer(), boolean(), boolean(), Clock.t()) :: t()
  def new(name, users, game_id, is_ranked, monitor_performance?, clock) do
    %__MODULE__{
      name: name,
      tanks: initialize_tanks(users),
      debris: initialize_debris(),
      map_width: GameMap.width(),
      map_height: GameMap.height(),
      upgrade_rates: Upgrade.rates(),
      game_id: game_id,
      is_ranked: is_ranked,
      projectiles: [],
      monitor_performance?: monitor_performance?,
      clock: clock
    }
  end

  @doc """
    Increase the tick count by one.
  """
  @spec increase_ticks(t()) :: t()
  def increase_ticks(game_state) do
    %{game_state | clock: Clock.tick(game_state.clock)}
  end

  @spec in_progress?(t()) :: boolean()
  def in_progress?(game_state), do: !Clock.done?(game_state.clock)

  @spec add_time_correction(t(), integer()) :: t()
  def add_time_correction(game_state, elapsed_time) do
    clock = Clock.add_time_correction(game_state.clock, elapsed_time)
    %{game_state | clock: clock}
  end

  @spec set_last_time(t(), integer) :: t()
  def set_last_time(game_state, last_time) do
    %{game_state | clock: Clock.set_last_time(game_state.clock, last_time)}
  end

  @spec stop_loop_after_max_ticks(t()) :: t()
  def stop_loop_after_max_ticks(game_state), do: %{game_state | should_stop?: true}

  @spec decrease_cooldowns(t()) :: t()
  def decrease_cooldowns(game_state) do
    Map.update!(game_state, :tanks, fn tanks ->
      Map.new(tanks, fn {id, tank} ->
        {id, Tank.decrease_cooldown(tank)}
      end)
    end)
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
      |> Enum.map(&Projectile.decrease_time_to_live(&1, @projectile_decay))
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

  @spec handle_tank_death(t()) :: t()
  def handle_tank_death(game_state) do
    updated_tanks =
      game_state.tanks
      |> Map.new(fn {id, tank} -> {id, Tank.mark_as_alive(tank)} end)
      |> Map.new(fn {id, tank} -> {id, respawn_if_dead(tank)} end)

    %{game_state | tanks: updated_tanks}
  end

  @spec handle_hp_regen(t()) :: t()
  def handle_hp_regen(game_state) do
    healed_tanks =
      game_state.tanks
      |> Map.new(fn {id, tank} -> {id, Tank.heal(tank, tank.hp_regen)} end)

    %{game_state | tanks: healed_tanks}
  end

  @spec handle_tanks(t(), [Action.t()]) :: t()
  def handle_tanks(game_state, actions) do
    game_state
    |> handle_actions(actions)
    |> handle_movement()
    |> handle_shoot()
  end

  defp handle_actions(game_state, actions) do
    Enum.reduce(actions, game_state, &handle_action/2)
  end

  defp handle_action(nil, game_state), do: game_state

  defp handle_action(action, game_state) do
    updated_tank =
      game_state.tanks
      |> Map.get(action.tank_id)
      |> handle_purchase(action)
      |> handle_target_update(action)
      |> handle_destination_update(action)

    %{game_state | tanks: Map.put(game_state.tanks, action.tank_id, updated_tank)}
  end

  defp handle_purchase(tank, %Action{purchase: nil}), do: tank

  defp handle_purchase(tank, action) do
    upgrade_func =
      case action.purchase do
        :speed -> &Tank.buy_speed_upgrade/1
        :fire_rate -> &Tank.buy_fire_rate_upgrade/1
        :projectile_damage -> &Tank.buy_projectile_damage_upgrade/1
        :max_hp -> &Tank.buy_max_hp_upgrade/1
        :body_damage -> &Tank.buy_body_damage_upgrade/1
        :hp_regen -> &Tank.buy_hp_regen_upgrade/1
      end

    tank
    |> upgrade_func.()
  end

  defp handle_target_update(tank, %Action{target: nil}), do: tank

  defp handle_target_update(tank, action) do
    tank
    |> Tank.set_target(action.target)
  end

  defp handle_destination_update(tank, %Action{destination: nil}), do: tank

  defp handle_destination_update(tank, action) do
    tank
    |> Tank.set_destination(action.destination)
  end

  defp handle_movement(game_state) do
    updated_tanks =
      game_state.tanks
      |> Map.values()
      |> Enum.map(fn
        %Tank{destination: nil} = tank ->
          {tank.id, tank}

        tank ->
          new_position = Position.next(tank.position, tank.destination, tank.speed)

          updated_tank =
            tank
            |> Tank.move(new_position)

          {updated_tank.id, updated_tank}
      end)
      |> Map.new()

    %{game_state | tanks: updated_tanks}
  end

  defp handle_shoot(game_state) do
    game_state.tanks
    |> Map.values()
    |> Enum.reduce(game_state, fn
      %Tank{target: nil}, acc_game_state -> acc_game_state
      tank, acc_game_state -> do_handle_shoot(tank, acc_game_state)
    end)
  end

  defp do_handle_shoot(tank, game_state) do
    {new_tank, projectile} =
      tank
      |> Tank.shoot()

    case projectile == nil do
      true ->
        game_state

      false ->
        game_state
        |> Map.update!(:projectiles, fn projectiles -> [projectile | projectiles] end)
        |> Map.update!(:tanks, fn tanks -> Map.put(tanks, new_tank.id, new_tank) end)
    end
  end

  defp handle_tank_tank_collisions(%{tanks: tanks_map} = game_state) do
    tanks = Map.values(tanks_map)

    collisions = Collisions.calculate_collisions(tanks, tanks)

    tanks_map =
      collisions
      |> Enum.reduce(tanks_map, fn {tank, other_tank}, tanks ->
        damaged_tank = Tank.hit(tanks[tank.id], Entity.get_body_damage(other_tank))

        tanks
        |> award_score_and_xp_if_dead(other_tank, damaged_tank)
        |> Map.replace!(tank.id, damaged_tank)
      end)

    %{game_state | tanks: tanks_map}
  end

  defp handle_tank_projectile_collisions(%{tanks: tanks_map, projectiles: projectiles} = game_state) do
    collisions =
      tanks_map
      |> Map.values()
      |> Collisions.calculate_collisions(projectiles)
      |> Enum.filter(fn {tank, projectile} -> tank.id != projectile.owner_id end)

    tanks_map =
      collisions
      |> Enum.reduce(tanks_map, fn {tank, projectile}, tanks ->
        projectile_damage = Entity.get_body_damage(projectile)
        damaged_tank = Tank.hit(tanks[tank.id], projectile_damage)

        tanks
        |> award_score_and_xp_if_dead(projectile, damaged_tank)
        |> Map.replace!(tank.id, damaged_tank)
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

    updated_state = handle_debris_collisions(game_state, collisions)

    tanks_map =
      collisions
      |> Enum.reduce(updated_state.tanks, fn {tank, _debris}, acc ->
        Map.replace!(acc, tank.id, Tank.hit(Map.get(acc, tank.id), Debris.default_body_damage()))
      end)

    %{updated_state | tanks: tanks_map}
  end

  defp handle_projectile_debris_collision(%{debris: debris, projectiles: projectiles} = game_state) do
    collisions =
      projectiles
      |> Collisions.calculate_collisions(debris)

    updated_state = handle_debris_collisions(game_state, collisions)

    projectiles =
      projectiles
      |> handle_projectiles_collision(Enum.map(collisions, fn {projectile, _} -> projectile end))

    %{updated_state | projectiles: projectiles}
  end

  defp handle_debris_collisions(game_state, collisions) do
    {debris_alive, debris_dead} =
      game_state.debris
      |> Enum.map(fn deb -> Enum.reduce(collisions, deb, &damage_debris_if_hit/2) end)
      |> Enum.split_with(&Debris.is_alive?/1)

    updated_tanks =
      Enum.reduce(collisions, game_state.tanks, fn {entity, deb}, tanks ->
        case Enum.find(debris_dead, nil, fn debris -> debris.id == deb.id end) do
          nil -> tanks
          single_debris -> award_score_and_xp(entity, single_debris, tanks)
        end
      end)

    %{game_state | debris: debris_alive, tanks: updated_tanks}
  end

  defp award_score_and_xp_if_dead(tanks, attacker, %Tank{} = damaged_tank) do
    case Tank.is_dead?(damaged_tank) do
      false -> tanks
      true -> award_score_and_xp(attacker, damaged_tank, tanks)
    end
  end

  defp award_score_and_xp(%Projectile{} = projectile, dead_entity, tanks) do
    tanks
    |> Map.get(projectile.owner_id)
    |> award_score_and_xp(dead_entity, tanks)
  end

  defp award_score_and_xp(%Tank{} = tank, %Debris{} = debris, tanks) do
    amount = Debris.get_points(debris)
    award_score_and_xp(tank, amount, tanks)
  end

  defp award_score_and_xp(%Tank{} = tank, %Tank{} = dead_tank, tanks) do
    amount = calculate_score_and_xp_gain(dead_tank)
    award_score_and_xp(tank, amount, tanks)
  end

  defp award_score_and_xp(%Tank{} = tank, amount, tanks) when is_integer(amount) do
    tanks
    |> Map.update!(tank.id, &Tank.increase_score(&1, amount))
    |> Map.update!(tank.id, &Tank.add_experience(&1, amount))
  end

  defp calculate_score_and_xp_gain(dead_tank) do
    Kernel.floor(dead_tank.experience * @experience_score_ratio_on_kill) + 100
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

  defp respawn_if_dead(tank) do
    case Tank.is_dead?(tank) do
      false ->
        tank

      true ->
        Tank.new(tank.id, tank.name)
        |> Tank.add_experience(Kernel.floor(tank.experience * @experience_loss_rate))
        |> Tank.mark_as_dead()
    end
  end

  defp generate_debris(game_state) do
    case @max_debris_count - Enum.count(game_state.debris) do
      full when full <= 0 ->
        game_state

      missing_count ->
        rand = Rand.uniform()

        debris_count =
          case rand do
            hit when hit < @max_debris_generation_rate -> max(round(rand * missing_count), 1)
            _ -> 0
          end

        new_debris = create_debris(debris_count)
        %{game_state | debris: Enum.concat(game_state.debris, new_debris)}
    end
  end

  defp create_debris(0) do
    []
  end

  defp create_debris(count) do
    for _ <- 1..count, do: Debris.new(Enum.random(@debris_size_probability))
  end

  defp initialize_tanks(users),
    do: users |> Map.new(fn user -> {user.id, Tank.new(user.id, user.name)} end)

  defp initialize_debris, do: create_debris(@max_debris_count)
end
