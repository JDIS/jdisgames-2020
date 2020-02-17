defmodule GameloopTest do
  use Diep.Io.DataCase, async: false

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action
  alias Diep.Io.Core.{GameState, Tank}
  alias Diep.Io.Gameloop
  alias Diep.Io.UsersRepository

  @user_name "Some user"
  @tank_id 555
  @expected_tank %Tank{
    name: @user_name,
    current_hp: Tank.default_hp(),
    max_hp: Tank.default_hp(),
    speed: Tank.default_speed(),
    experience: 0,
    position: {0, 0}
  }

  setup do
    {:ok, user} = UsersRepository.create_user(%{name: @user_name})
    {:ok, _pid} = start_supervised(Gameloop)
    [users: [user]]
  end

  test "get_state/0 returns expected initial test", %{users: users} do
    assert %GameState{
             in_progress: false,
             tanks: %{List.first(users).id => @expected_tank},
             last_time: 0,
             map_width: 10_000,
             map_height: 10_000
           } == Gameloop.get_state()
  end

  test "start_game/0 changes in_progress to true" do
    :ok = Gameloop.start_game()
    assert Gameloop.get_state().in_progress == true
  end

  test "A gameloop loop with a valid destination moves the desired tank" do
    ActionStorage.store_action(Action.new(@tank_id, %{destination: {500, 0}}))
    state = GameState.new([%{id: @tank_id, name: "some_name"}])
    {:noreply, result} = Gameloop.handle_info(:loop, state)
    {x, y} = result.tanks[@tank_id].position
    assert x > 0
    assert y == 0
  end
end
