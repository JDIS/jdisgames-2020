defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Action, Debris, Entity, GameMap, GameState, Position, Projectile, Tank}
  alias Diep.Io.Users.User

  @max_ticks 324
  @user_name "SomeUsername"
  @user_id 420

  setup do
    [game_state: GameState.new([%User{name: @user_name, id: @user_id}], @max_ticks)]
  end

  test "new/1 creates a default GameState", %{game_state: game_state} do
    assert %GameState{
             in_progress: false,
             tanks: %{@user_id => %Tank{}},
             debris: debris,
             last_time: 0,
             map_width: map_width,
             map_height: map_height,
             ticks: 1,
             max_ticks: @max_ticks
           } = game_state

    assert map_width == GameMap.width()
    assert map_height == GameMap.height()
    assert is_list(debris) && !Enum.empty?(debris)
  end

  test "start_game/1 sets in_progress to true", %{game_state: game_state} do
    assert GameState.start_game(game_state).in_progress == true
  end

  test "stop_game/1 sets in_progress to true", %{game_state: game_state} do
    assert GameState.stop_game(game_state).in_progress == false
  end

  test "handle_players/2 does not move player if destination is nil", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@user_id)

    updated_tank =
      [Action.new(@user_id)]
      |> GameState.handle_players(game_state)
      |> Map.get(:tanks)
      |> Map.get(@user_id)

    assert tank.position == updated_tank.position
  end

  test "handle_players/2 moves player if given a destination", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@user_id)

    updated_tank =
      [Action.new(@user_id, destination: Position.random())]
      |> GameState.handle_players(game_state)
      |> Map.get(:tanks)
      |> Map.get(@user_id)

    assert tank.position != updated_tank.position
  end

  test "handle_debris/1 does not add debris if none is missing", %{game_state: game_state} do
    updated_state = GameState.handle_debris(game_state)
    assert Enum.count(game_state.debris) == Enum.count(updated_state.debris)
  end

  test "handle_debris/1 generates debris if cap is not reached", %{game_state: game_state} do
    game_state = %{game_state | debris: Enum.take_every(game_state.debris, 2)}
    updated_state = GameState.handle_debris(game_state)
    assert Enum.count(updated_state.debris) > Enum.count(game_state.debris)
  end

  test "handle_shoot/2 does nothing if target is nil", %{game_state: game_state} do
    updated_state =
      [Action.new(@user_id, target: nil)]
      |> GameState.handle_players(game_state)

    assert updated_state == game_state
  end

  test "handle_shoot/2 adds projectiles and sets cooldowns", %{game_state: game_state} do
    updated_state =
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)

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
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)

    assert Enum.empty?(updated_state.projectiles)
  end

  test "handle_projectiles/1 decays projectiles", %{game_state: game_state} do
    game_state =
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)

    [projectile] = game_state.projectiles

    updated_game_state = GameState.handle_projectiles(game_state)

    [updated_projectile] = updated_game_state.projectiles

    assert projectile.hp > updated_projectile.hp
  end

  test "handle_projectiles/1 removes projectiles without hp", %{game_state: game_state} do
    projectile = Projectile.new(@user_id, Position.random(), Position.random(), 0, hp: 0)

    updated_game_state =
      game_state
      |> Map.put(:projectiles, [projectile])
      |> GameState.handle_projectiles()

    assert Enum.empty?(updated_game_state.projectiles)
  end

  test "handle_projectiles/1 moves projectiles", %{game_state: game_state} do
    game_state =
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)

    [projectile] = game_state.projectiles

    updated_game_state = GameState.handle_projectiles(game_state)

    [updated_projectile] = updated_game_state.projectiles

    assert projectile.position != updated_projectile.position
  end

  test "decrease_cooldowns/1 decreases tanks cooldown", %{game_state: game_state} do
    tank =
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)
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
        [Action.new(@user_id, purchase: stat)]
        |> GameState.handle_players(game_state)
        |> get_tank(@user_id)

      assert Map.get(upgraded_tank, stat) != Map.get(tank, stat)
    end
  end

  test "handle_collisions/1 decreases hp of colliding tanks" do
    user1 = %User{name: @user_name, id: @user_id}
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new([user1, user2], @max_ticks)
    game_state = move_tanks_to_origin(game_state)

    expected_tanks =
      game_state.tanks
      |> Map.new(fn {id, tank} -> {id, Tank.hit(tank, Tank.default_body_damage())} end)

    assert GameState.handle_collisions(game_state).tanks == expected_tanks
  end

  test "handle_collisions/1 does not remove tanks that are not colliding with other tanks" do
    user1 = %User{name: @user_name, id: @user_id}
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new([user1, user2], @max_ticks)

    game_state = move_tanks_out_of_collision(game_state)

    assert GameState.handle_collisions(game_state).tanks == game_state.tanks
  end

  test "handle_collisions/1 decreases hp of all tanks hit by projectiles" do
    {tank, game_state} = setup_tank_projectile_collision()

    updated_game_state = GameState.handle_collisions(game_state)

    assert Map.fetch!(updated_game_state.tanks, tank.id).current_hp ==
             Tank.hit(tank, tank.projectile_damage).current_hp
  end

  test "handle_collisions/1 does not decrease hp of tank hit by it's own projectile", %{game_state: game_state} do
    game_state =
      [Action.new(@user_id, target: Position.random())]
      |> GameState.handle_players(game_state)

    tank = Map.fetch!(game_state.tanks, @user_id)

    updated_game_state = GameState.handle_collisions(game_state)

    assert Map.fetch!(updated_game_state.tanks, @user_id) == tank
  end

  test "handle_collisions/1 removes projectiles that hit a tank" do
    {_, game_state} = setup_tank_projectile_collision()

    assert GameState.handle_collisions(game_state).projectiles == []
  end

  test "handle_collisions/1 reduces hp of tanks that hit a debris" do
    {tank, _debris, game_state} = setup_tank_debris_collision()

    updated_game_state = GameState.handle_collisions(game_state)
    assert Map.fetch!(updated_game_state.tanks, tank.id) == Tank.hit(tank, Debris.default_body_damage())
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

  defp get_tank(game_state, id) do
    game_state |> Map.get(:tanks) |> Map.get(id)
  end

  defp move_tanks_to_origin(game_state) do
    update_all_tanks(game_state, fn {id, tank} -> {id, Tank.move(tank, {0, 0})} end)
  end

  defp move_tanks_out_of_collision(game_state) do
    update_all_tanks(game_state, fn {id, tank} -> {id, Tank.move(tank, {0, id * Entity.get_radius(tank) * 2})} end)
  end

  defp update_all_tanks(game_state, func) do
    %{game_state | tanks: Map.new(game_state.tanks, func)}
  end

  defp setup_tank_projectile_collision do
    user1 = %User{name: @user_name, id: @user_id}
    # User 2 only serves as the projectile's owner
    user2 = %User{name: @user_name <> "2", id: @user_id + 1}
    game_state = GameState.new([user1, user2], @max_ticks)

    tank1 = Map.fetch!(game_state.tanks, user1.id)

    projectile = Projectile.new(user2.id, Entity.get_position(tank1), 0, tank1.projectile_damage)

    game_state = %{game_state | projectiles: [projectile]}

    {tank1, game_state}
  end

  defp setup_tank_debris_collision do
    user = %User{name: @user_name, id: @user_id}
    game_state = GameState.new([user], @max_ticks)

    tank = Map.fetch!(game_state.tanks, user.id)

    debris = Debris.new(:large)
    debris = %{debris | position: Entity.get_position(tank)}

    game_state = %{game_state | debris: [debris]}

    {tank, debris, game_state}
  end

  defp setup_projectile_debris_collision do
    projectile = Projectile.new(1, {0, 0}, 0, 10)
    game_state = GameState.new([], @max_ticks)

    debris = Debris.new(:large)
    debris = %{debris | position: Entity.get_position(projectile)}

    game_state = %{game_state | debris: [debris], projectiles: [projectile]}

    {projectile, debris, game_state}
  end
end
