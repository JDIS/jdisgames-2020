defmodule GameloopTest do
  use Diep.Io.DataCase, async: false

  alias Diep.Io.Core.{GameState, Tank}
  alias Diep.Io.Gameloop
  alias Diep.Io.UsersRepository

  @user_name "Some user"
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
             tanks: %{List.first(users).id => @expected_tank}
           } == Gameloop.get_state()
  end

  test "start_game/0 changes in_progress to true" do
    :ok = Gameloop.start_game()
    assert Gameloop.get_state().in_progress == true
  end
end
