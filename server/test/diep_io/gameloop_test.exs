defmodule GameloopTest do
  use ExUnit.Case, async: true

  alias Diep.Io.{Gameloop, Tank}

  @expected_tank %Tank{
    name: "Tank",
    current_hp: Tank.default_hp(),
    max_hp: Tank.default_hp(),
    speed: Tank.default_speed(),
    experience: 0
  }

  setup do
    {:ok, _pid} = start_supervised({Gameloop, [@expected_tank.name]})
    :ok
  end

  test "get_state/0 returns expected initial test" do
    assert %{
             in_progress: false,
             tanks: [@expected_tank]
           } == Gameloop.get_state()
  end

  test "start_game/0 changes in_progress to true" do
    :ok = Gameloop.start_game()
    assert Gameloop.get_state().in_progress == true
  end
end
