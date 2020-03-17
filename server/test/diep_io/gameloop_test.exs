defmodule GameloopTest do
  use Diep.Io.DataCase, async: false

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.{Action, GameState}
  alias Diep.Io.Gameloop
  alias Diep.Io.UsersRepository

  @game_time 1000
  @user_name "Some user"
  @tank_id 555

  setup do
    {:ok, user} = UsersRepository.create_user(%{name: @user_name})
    {:ok, _pid} = start_supervised({Gameloop, [@game_time]})
    [users: [user]]
  end

  test "get_state/0 returns expected initial test" do
    assert %GameState{} = Gameloop.get_state()
  end

  test "start_game/0 changes in_progress to true" do
    :ok = Gameloop.start_game()
    assert Gameloop.get_state().in_progress == true
  end

  test "A gameloop loop with a valid destination moves the desired tank" do
    ActionStorage.store_action(Action.new(@tank_id, %{destination: {500, 0}}))

    state = GameState.new([%{id: @tank_id, name: "some_name"}], @game_time) |> GameState.start_game()

    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.tanks[@tank_id].position != state.tanks[@tank_id].position
  end

  test "A single iterations of handle_info does not stop the game with a game time of 2" do
    ActionStorage.store_action(Action.new(@tank_id, %{destination: {500, 0}}))
    state = GameState.new([%{id: @tank_id, name: "some_name"}], 2) |> GameState.start_game()
    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.in_progress == true
  end

  test "A single iterations of handle_info stops the game with a game time of 1" do
    ActionStorage.store_action(Action.new(@tank_id, %{destination: {500, 0}}))
    state = GameState.new([%{id: @tank_id, name: "some_name"}], 1) |> GameState.start_game()
    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.in_progress == false
  end

  test "Cannot do a loop if the game is not in progress" do
    state = GameState.new([%{id: @tank_id, name: "some_name"}], 2)
    assert state.in_progress == false
    assert_raise FunctionClauseError, fn -> Gameloop.handle_info(:loop, state) end
  end
end
