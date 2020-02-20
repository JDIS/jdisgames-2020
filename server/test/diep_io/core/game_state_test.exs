defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Action, GameMap, GameState, Tank}
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
      [Action.new(@user_id, destination: {1, 1})]
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
end
