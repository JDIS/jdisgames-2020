defmodule DebrisTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.Debris

  @damage 10
  @expected_size :medium

  setup do
    [debris: Debris.new(@expected_size)]
  end

  test "new/1 creates a debris", %{debris: debris} do
    assert %Debris{
             current_hp: hp,
             size: @expected_size,
             speed: speed,
             position: {_, _}
           } = debris

    assert speed == Debris.default_speed()
    assert hp == Debris.default_hp(@expected_size)
  end

  test "new/0 creates a small debris" do
    assert Debris.new().size == :small
  end

  test "hit/2 damages the given debris", %{debris: debris} do
    assert Debris.hit(debris, @damage).current_hp == Debris.default_hp(debris.size) - @damage
  end

  test "is_dead?/1 determines if the given debris is dead", %{debris: debris} do
    dead_debris = Debris.hit(debris, debris.current_hp)
    assert Debris.is_dead?(dead_debris)
  end

  test "is_alive?/1 determines if the given debris is alive", %{debris: debris} do
    assert Debris.is_alive?(debris)
  end

  test "get_points/1 gives the correct amount of points", %{debris: debris} do
    assert Debris.get_points(debris) == 50
  end
end
