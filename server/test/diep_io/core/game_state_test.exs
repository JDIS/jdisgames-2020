defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{Action, GameState, Tank}

  @tank_name "Tank"
  @default_tank Tank.new(@tank_name)

  @expected_game_state %GameState{
    in_progress: false,
    tanks: %{@tank_name => @default_tank}
  }

  setup do
    [game_state: GameState.new([@tank_name])]
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
    tank = game_state |> Map.get(:tanks) |> Map.get(@tank_name)

    updated_tank =
      game_state
      |> GameState.handle_players([Action.new(@tank_name)])
      |> Map.get(:tanks)
      |> Map.get(@tank_name)

    assert tank.position == updated_tank.position
  end

  test "handle_players/2 moves player if given a destination", %{game_state: game_state} do
    tank = game_state |> Map.get(:tanks) |> Map.get(@tank_name)

    updated_tank =
      game_state
      |> GameState.handle_players([Action.new(@tank_name, destination: {1, 1})])
      |> Map.get(:tanks)
      |> Map.get(@tank_name)

    assert tank.position != updated_tank.position
  end
end
