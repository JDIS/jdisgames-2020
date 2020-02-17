defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Action, GameState, Tank}
  alias Diep.Io.Users.User

  @user_name "SomeUsername"
  @user_id 420
  @default_tank Tank.new(@user_name)

  @expected_game_state %GameState{
    in_progress: false,
    tanks: %{@user_id => @default_tank},
    last_time: 0
  }

  setup do
    [game_state: GameState.new([%User{name: @user_name, id: @user_id}])]
  end

  test "new/1 creates a default GameState", %{game_state: game_state} do
    assert game_state == @expected_game_state
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
end
