defmodule PositionTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.Position
  alias Jason

  @origin {0, 0}

  test "new/3 returns destination if distance <= speed" do
    destination = {1, 0}
    assert Position.new(@origin, destination, 1) == destination
  end

  test "new/3 returns a new position if distance > speed" do
    destination = {10, 0}
    assert Position.new(@origin, destination, 3) == {3, 0}
  end

  test "new/3 returns a position on the straight line between 2 positions" do
    from = {0, 1}
    destination = {10, 6}
    fx = fn x -> 0.5 * x + 1 end
    fy = fn y -> 2 * y - 2 end
    {x, y} = Position.new(from, destination, 3)

    assert fx.(x) == y
    assert fy.(y) == x
  end
end
