defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias DiepIO.Core.{
    Action,
    Clock,
    Debris,
    Entity,
    GameMap,
    GameState,
    Position,
    Projectile,
    Tank
  }

  alias DiepIOSchemas.User

  @max_ticks 324
  @tick_rate 3
  @user_name "SomeUsername"
  @user_id 420
  @game_name :test_game
  @game_id 123
  @clock Clock.new(@tick_rate, @max_ticks)
  @game_params %{
    max_debris_count: 400,
    max_debris_generation_rate: 0.15
  }

  setup do
    [
      game_state:
        GameState.new(
          @game_name,
          [%User{name: @user_name, id: @user_id}],
          @game_id,
          false,
          false,
          @clock,
          @game_params
        )
    ]
  end

  test "new/1 creates a default GameState", %{game_state: game_state} do
    assert %GameState{
             tanks: %{@user_id => %Tank{}},
             debris: debris,
             map_width: map_width,
             map_height: map_height,
             should_stop?: should_stop?
           } = game_state

    assert map_width == GameMap.width()
    assert map_height == GameMap.height()
    assert is_list(debris) && !Enum.empty?(debris)
    assert should_stop? == false
  end

  test "increase_ticks/1 increases ticks by 1", %{game_state: game_state} do
    game_state = GameState.increase_ticks(game_state)

    assert game_state.clock.current_tick == 1
  end

  test "stop_loop_after_max_ticks/1 sets should_stop? to true", %{game_state: game_state} do
    new_state = GameState.stop_loop_after_max_ticks(game_state)

    assert new_state.should_stop? == true
  end

  test "handle_tanks/2 does not move player if destination is nil", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@user_id)

    updated_tank =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id)])
      |> Map.get(:tanks)
      |> Map.get(@user_id)

    assert tank.position == updated_tank.position
  end

  test "handle_tanks/2 moves player if given a destination", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@user_id)

    updated_tank =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, destination: Position.random())])
      |> Map.get(:tanks)
      |> Map.get(@user_id)

    assert tank.position != updated_tank.position
  end

  test "handle_tanks/2 change the cannon angle if given a target", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@user_id)

    updated_tank =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, destination: Position.random(), target: Position.random())])
      |> Map.get(:tanks)
      |> Map.get(@user_id)

    assert updated_tank.cannon_angle != tank.cannon_angle
  end

  test "handle_debris/1 does not add debris if none is missing", %{game_state: game_state} do
    updated_state = GameState.handle_debris(game_state)
    assert Enum.count(game_state.debris) == Enum.count(updated_state.debris)
  end

  test "handle_shoot/2 does nothing if target is nil", %{game_state: game_state} do
    updated_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: nil)])

    assert updated_state == game_state
  end

  test "handle_shoot/2 adds projectiles and sets cooldowns", %{game_state: game_state} do
    updated_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])

    tank = get_tank(game_state, @user_id)
    updated_tank = get_tank(updated_state, @user_id)

    assert Enum.count(updated_state.projectiles) == 1
    assert tank.cooldown != updated_tank.cooldown
  end

  test "handle_shoot/2 does nothing if tank is on cooldown", %{game_state: game_state} do
    game_state =
      Map.update!(game_state, :tanks, fn tanks ->
        Map.update!(tanks, @user_id, &Tank.set_cooldown/1)
      end)

    updated_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])

    assert Enum.empty?(updated_state.projectiles)
  end

  test "handle_projectiles/1 decays projectiles", %{game_state: game_state} do
    game_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])

    [projectile] = game_state.projectiles

    updated_game_state = GameState.handle_projectiles(game_state)

    [updated_projectile] = updated_game_state.projectiles

    assert projectile.time_to_live > updated_projectile.time_to_live
  end

  test "handle_projectiles/1 removes projectiles without hp", %{game_state: game_state} do
    projectile = Projectile.new(@user_id, Position.random(), Position.random(), 0, time_to_live: 0)

    updated_game_state =
      game_state
      |> Map.put(:projectiles, [projectile])
      |> GameState.handle_projectiles()

    assert Enum.empty?(updated_game_state.projectiles)
  end

  test "handle_projectiles/1 moves projectiles", %{game_state: game_state} do
    game_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])

    [projectile] = game_state.projectiles

    updated_game_state = GameState.handle_projectiles(game_state)

    [updated_projectile] = updated_game_state.projectiles

    assert projectile.position != updated_projectile.position
  end

  test "decrease_cooldowns/1 decreases tanks cooldown", %{game_state: game_state} do
    tank =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])
      |> GameState.decrease_cooldowns()
      |> get_tank(@user_id)

    assert tank.cooldown == tank.fire_rate - 1
  end

  test "handle_purchase/2 buys tank upgrades", %{game_state: game_state} do
    game_state =
      Map.update!(game_state, :tanks, fn tanks ->
        Map.update!(tanks, @user_id, &Tank.add_upgrade_tokens(&1, 1))
      end)

    tank = get_tank(game_state, @user_id)

    for stat <- [:speed, :fire_rate, :projectile_damage, :max_hp] do
      upgraded_tank =
        game_state
        |> GameState.handle_tanks([Action.new(@user_id, purchase: stat)])
        |> get_tank(@user_id)

      assert Map.get(upgraded_tank, stat) != Map.get(tank, stat)
    end
  end

  test "handle_collisions/1 decreases hp of colliding tanks" do
    user1 = %User{name: @user_name, id: @user_id}
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new("game_name", [user1, user2], 0, false, false, @clock, @game_params)
    game_state = move_tanks_to_origin(game_state)

    expected_tanks =
      game_state.tanks
      |> Map.new(fn {id, tank} -> {id, Tank.hit(tank, Tank.default_body_damage())} end)

    assert GameState.handle_collisions(game_state).tanks == expected_tanks
  end

  test "handle_collisions/1 does not remove tanks that are not colliding with other tanks" do
    user1 = %User{name: @user_name, id: @user_id}
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new("game_name", [user1, user2], 0, false, false, @clock, @game_params)

    game_state = move_tanks_out_of_collision(game_state)

    assert GameState.handle_collisions(game_state).tanks == game_state.tanks
  end

  test "handle_collisions/1 decreases hp of all tanks hit by projectiles" do
    {tank, _, game_state} = setup_tank_projectile_collision()

    updated_game_state = GameState.handle_collisions(game_state)

    assert Map.fetch!(updated_game_state.tanks, tank.id).current_hp ==
             Tank.hit(tank, tank.projectile_damage).current_hp
  end

  test "handle_collisions/1 does not decrease hp of tank hit by it's own projectile", %{
    game_state: game_state
  } do
    game_state =
      game_state
      |> GameState.handle_tanks([Action.new(@user_id, target: Position.random())])

    tank = Map.fetch!(game_state.tanks, @user_id)

    updated_game_state = GameState.handle_collisions(game_state)

    assert Map.fetch!(updated_game_state.tanks, @user_id) == tank
  end

  test "handle_collisions/1 removes projectiles that hit a tank" do
    {_, _, game_state} = setup_tank_projectile_collision()

    assert GameState.handle_collisions(game_state).projectiles == []
  end

  test "handle_collisions/1 reduces hp of tanks that hit a debris" do
    {tank, _debris, game_state} = setup_tank_debris_collision()

    updated_game_state = GameState.handle_collisions(game_state)

    assert Map.fetch!(updated_game_state.tanks, tank.id) ==
             Tank.hit(tank, Debris.default_body_damage())
  end

  test "handle_collisions/1 reduces hp of debris hit by a tank" do
    {_tank, debris, game_state} = setup_tank_debris_collision()

    updated_game_state = GameState.handle_collisions(game_state)
    assert updated_game_state.debris == [Debris.hit(debris, Tank.default_body_damage())]
  end

  test "handle_collisions/1 removes debris that die after collision with tank" do
    {_tank, debris, game_state} = setup_tank_debris_collision()

    dead_debris = Debris.hit(debris, Debris.default_hp(:large))
    game_state = %{game_state | debris: [dead_debris]}

    updated_game_state = GameState.handle_collisions(game_state)
    assert updated_game_state.debris == []
  end

  test "handle_collisions/1 removes projectiles that hit a debris" do
    {_, _, game_state} = setup_projectile_debris_collision()

    assert GameState.handle_collisions(game_state).projectiles == []
  end

  test "handle_collisions/1 reduces hp of debris hit by a projectile" do
    {projectile, debris, game_state} = setup_projectile_debris_collision()

    updated_game_state = GameState.handle_collisions(game_state)
    assert updated_game_state.debris == [Debris.hit(debris, Entity.get_body_damage(projectile))]
  end

  test "handle_collisions/1 removes debris that die after collision with projectile" do
    {_projectile, debris, game_state} = setup_tank_debris_collision()

    dead_debris = Debris.hit(debris, Debris.default_hp(:large))
    game_state = %{game_state | debris: [dead_debris]}

    updated_game_state = GameState.handle_collisions(game_state)
    assert updated_game_state.debris == []
  end

  test "handle_collisions/1 gives points to tanks that destroyed debris by colliding" do
    {_tank, debris, game_state} = setup_tank_debris_collision(:small)
    updated_game_state = GameState.handle_collisions(game_state)

    assert get_tank(updated_game_state, @user_id).score ==
             get_tank(game_state, @user_id).score + Debris.get_points(debris)
  end

  test "handle_collisions/1 gives points to tanks that destroyed debris by shooting" do
    {_projectile, debris, game_state} = setup_projectile_debris_collision(:small)
    updated_game_state = GameState.handle_collisions(game_state)

    assert get_tank(updated_game_state, @user_id).score ==
             get_tank(game_state, @user_id).score + Debris.get_points(debris)
  end

  test "handle_collisions/1 gives points to tanks that destroyed another tank by shooting" do
    {_, tank, game_state} = setup_tank_projectile_collision()

    updated_game_state =
      game_state
      |> update_all_projectiles(fn projectile ->
        Map.replace!(projectile, :damage, tank.current_hp)
      end)
      |> GameState.handle_collisions()

    assert get_tank(updated_game_state, tank.id).score > get_tank(game_state, tank.id).score
  end

  test "handle_collision/1 gives points to tanks that destroyed another tank by colliding" do
    game_state =
      setup_tank_tank_collision()
      |> update_single_tank(@user_id, fn tank -> Map.replace!(tank, :body_damage, tank.max_hp) end)
      |> GameState.handle_collisions()

    assert game_state.tanks[@user_id].score != game_state.tanks[@user_id + 1].score
  end

  test "handle_tank_death/1 respawns dead tanks", %{game_state: game_state} do
    tank =
      game_state
      |> kill_tanks()
      |> give_experience(100)
      |> GameState.handle_tank_death()
      |> get_tank(@user_id)

    assert tank.has_died == true
    assert tank.experience < 100
  end

  test "handle_tank_death/1 tags a tank as dead only during one turn", %{game_state: game_state} do
    tank =
      game_state
      |> kill_tanks()
      |> GameState.handle_tank_death()
      |> GameState.handle_tank_death()
      |> get_tank(@user_id)

    assert tank.has_died == false
  end

  test "handle_hp_regen/1 heals every tanks", %{game_state: game_state} do
    state_with_damaged_tanks =
      game_state
      |> update_all_tanks(fn {id, tank} -> {id, Tank.hit(tank, 3)} end)

    state_with_healed_tanks = GameState.handle_hp_regen(state_with_damaged_tanks)

    for id <- Map.keys(game_state.tanks) do
      assert state_with_damaged_tanks.tanks[id].current_hp <
               state_with_healed_tanks.tanks[id].current_hp
    end
  end

  defp get_tank(game_state, id) do
    game_state |> Map.get(:tanks) |> Map.get(id)
  end

  defp kill_tanks(game_state) do
    update_all_tanks(game_state, fn {id, tank} -> {id, Tank.hit(tank, tank.max_hp)} end)
  end

  defp give_experience(game_state, amount) do
    update_all_tanks(game_state, fn {id, tank} -> {id, Tank.add_experience(tank, amount)} end)
  end

  defp move_tanks_to_origin(game_state) do
    update_all_tanks(game_state, fn {id, tank} -> {id, Tank.move(tank, {0, 0})} end)
  end

  defp move_tanks_out_of_collision(game_state) do
    update_all_tanks(game_state, fn {id, tank} ->
      {id, Tank.move(tank, {0, id * Entity.get_radius(tank) * 2})}
    end)
  end

  defp update_all_tanks(game_state, func) do
    %{game_state | tanks: Map.new(game_state.tanks, func)}
  end

  defp update_single_tank(game_state, tank_id, func) do
    %{game_state | tanks: Map.update!(game_state.tanks, tank_id, func)}
  end

  defp update_all_projectiles(game_state, func) do
    %{game_state | projectiles: Enum.map(game_state.projectiles, func)}
  end

  defp setup_tank_tank_collision do
    user1 = %User{name: @user_name, id: @user_id}
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}

    GameState.new("game_name", [user1, user2], 0, false, false, @clock, @game_params)
    |> move_tanks_to_origin()
  end

  defp setup_tank_projectile_collision do
    user1 = %User{name: @user_name, id: @user_id}
    # User 2 only serves as the projectile's owner
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new("game_name", [user1, user2], 0, false, false, @clock, @game_params)

    tank1 = Map.fetch!(game_state.tanks, user1.id)
    tank2 = Map.fetch!(game_state.tanks, user2.id)

    projectile = Projectile.new(user2.id, Entity.get_position(tank1), 0, tank2.projectile_damage)

    game_state = %{game_state | projectiles: [projectile]}

    {tank1, tank2, game_state}
  end

  defp setup_tank_debris_collision(debris_size \\ :large) do
    user = %User{name: @user_name, id: @user_id}
    game_state = GameState.new("game_name", [user], 0, false, false, @clock, @game_params)

    tank = Map.fetch!(game_state.tanks, user.id)

    debris = Debris.new(debris_size)
    debris = %{debris | position: Entity.get_position(tank)}

    game_state = %{game_state | debris: [debris]}

    {tank, debris, game_state}
  end

  defp setup_projectile_debris_collision(debris_size \\ :large) do
    user = %User{name: @user_name, id: @user_id}
    projectile = Projectile.new(user.id, {0, 0}, 0, 20)
    game_state = GameState.new("game_name", [user], 0, false, false, @clock, @game_params)

    debris = Debris.new(debris_size)
    debris = %{debris | position: Entity.get_position(projectile)}

    game_state = %{game_state | debris: [debris], projectiles: [projectile]}

    {projectile, debris, game_state}
  end
end
