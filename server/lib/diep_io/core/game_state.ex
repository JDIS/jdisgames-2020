defmodule Diep.Io.Core.GameState do
  @moduledoc """
  Module that handles most of the game's business logic
  (handle player actions, debris generation, etc).
  """

  alias Diep.Io.Collisions
  alias Diep.Io.Core.{Action, Debris, Entity, GameMap, Position, Projectile, Tank, Upgrade}
  alias Diep.Io.Users.User
  alias :erlang, as: Erlang
  alias :rand, as: Rand

  @max_debris_count 1000
  @max_debris_generation_rate 0.5
  @debris_size_probability [:small, :small, :small, :medium, :medium, :large]
  @projectile_decay 2
  @experience_loss_rate 0.5
  @experience_score_ratio_on_kill 0.1

  @derive {Jason.Encoder, except: [:last_time, :time_corrections, :should_stop?, :tick_rate, :monitor_performance]}
  defstruct [
    :name,
    :tanks,
    :last_time,
    :map_width,
    :map_height,
    :ticks,
    :max_ticks,
    :upgrade_rates,
    :game_id,
    :debris,
    :persistent?,
    :projectiles,
    :tick_rate,
    :monitor_performance?,
    time_corrections: [],
    should_stop?: false
  ]

  @type t :: %__MODULE__{
          name: atom(),
          tanks: %{integer() => Tank.t()},
          debris: [Debris.t()],
          last_time: integer(),
          map_width: integer(),
          map_height: integer(),
          ticks: integer(),
          max_ticks: integer(),
          upgrade_rates: %{
            :body_damage => float(),
            :fire_rate => float(),
            :max_hp => float(),
            :projectile_damage => float(),
            :speed => float()
          },
          game_id: integer(),
          persistent?: boolean(),
          projectiles: [Projectile.t()],
          time_corrections: [integer()],
          tick_rate: integer(),
          monitor_performance?: boolean(),
          should_stop?: boolean()
        }

  @spec new(atom(), [User.t()], integer(), integer(), boolean(), integer(), boolean()) :: t()
  def new(name, users, max_ticks, game_id, persistent?, tick_rate, monitor_performance?) do
    %__MODULE__{
      name: name,
      tanks: initialize_tanks(users),
      debris: initialize_debris(),
      last_time: 0,
      map_width: GameMap.width(),
      map_height: GameMap.height(),
      upgrade_rates: Upgrade.rates(),
      max_ticks: max_ticks,
      ticks: 0,
      game_id: game_id,
      persistent?: persistent?,
      tick_rate: tick_rate,
      projectiles: [],
      monitor_performance?: monitor_performance?
    }
  end

  @doc """
    Increase the tick count by one.
  """
  @spec increase_ticks(t()) :: t()
  def increase_ticks(game_state), do: Map.update!(game_state, :ticks, &(&1 + 1))

  @spec in_progress?(t()) :: boolean()
  def in_progress?(game_state), do: game_state.ticks <= game_state.max_ticks

  @spec add_time_correction(t(), integer()) :: t()
  def add_time_correction(%__MODULE__{time_corrections: corrections} = game_state, elapsed_time)
      when length(corrections) >= 16 do
    add_time_correction(%{game_state | time_corrections: Enum.drop(corrections, -1)}, elapsed_time)
  end

  def add_time_correction(%__MODULE__{time_corrections: corrections} = game_state, elapsed_time) do
    correction = elapsed_time - calculate_iteration_duration_native(game_state.tick_rate)
    %{game_state | time_corrections: [correction | corrections]}
  end

  @spec calculate_correction(t()) :: integer()
  def calculate_correction(game_state) do
    case game_state.time_corrections do
      [] -> 0
      corrections -> Kernel.floor(Enum.sum(corrections) / Enum.count(corrections))
    end
  end

  @spec calculate_elasped_time(t(), integer()) :: integer()
  def calculate_elasped_time(%{last_time: 0, tick_rate: tick_rate}, _now) do
    calculate_iteration_duration_native(tick_rate)
  end

  def calculate_elasped_time(%{last_time: last_time}, now), do: now - last_time

  @spec calculate_time_to_wait(t(), integer()) :: integer()
  def calculate_time_to_wait(state, elapsed_time) do
    time_correction = calculate_correction(state)

    (calculate_iteration_duration_native(state.tick_rate) - elapsed_time - time_correction)
    |> max(0)
    |> Erlang.convert_time_unit(:native, :millisecond)
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

  @spec handle_tank_death(t()) :: t()
  def handle_tank_death(game_state) do
    updated_tanks =
      game_state.tanks
      |> Map.new(fn {id, tank} -> {id, Tank.mark_as_alive(tank)} end)
      |> Map.new(fn {id, tank} -> {id, respawn_if_dead(tank)} end)

    %{game_state | tanks: updated_tanks}
  end

  defp handle_action(action, game_state) do
    game_state
    |> handle_purchase(action)
    |> handle_shoot(action)
    |> handle_movement(action)
  end

  defp handle_movement(game_state, %Action{destination: nil}), do: game_state

  defp handle_movement(game_state, action) do
    Map.update!(game_state, :tanks, fn tanks ->
      Map.update!(tanks, action.tank_id, fn tank ->
        new_position = Position.next(tank.position, action.destination, tank.speed)

        # TODO: remove me when implementing real metric for scores.
        Tank.move(tank, new_position)
        |> Tank.increase_score(:rand.uniform(10))
      end)
    end)
  end

  defp handle_shoot(game_state, %Action{target: nil}), do: game_state

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

  defp handle_purchase(game_state, %Action{purchase: nil}), do: game_state

  defp handle_purchase(game_state, action) do
    upgrade_func =
      case action.purchase do
        :speed -> &Tank.buy_speed_upgrade/1
        :fire_rate -> &Tank.buy_fire_rate_upgrade/1
        :projectile_damage -> &Tank.buy_projectile_damage_upgrade/1
        :max_hp -> &Tank.buy_max_hp_upgrade/1
        :body_damage -> &Tank.buy_body_damage_upgrade/1
      end

    upgraded_tank =
      game_state.tanks
      |> Map.get(action.tank_id)
      |> upgrade_func.()

    updated_tanks = Map.put(game_state.tanks, action.tank_id, upgraded_tank)
    %{game_state | tanks: updated_tanks}
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

    tanks_map =
      collisions
      |> Enum.filter(fn {tank, projectile} -> tank.id != projectile.owner_id end)
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

  defp calculate_iteration_duration_native(tick_rate) do
    Erlang.convert_time_unit(div(1000, tick_rate), :millisecond, :native)
  end
end
