defmodule GameStateTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.{GameState, Tank}

  @tank_name "Tank"
  @default_tank Tank.new(@tank_name)

  @expected_game_state %GameState{
    in_progress: false,
    tanks: [@default_tank]
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
end
