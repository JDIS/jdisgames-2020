defmodule PositionTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.Position
  alias Jason
  alias :math, as: Math

  @origin {0, 0}

  test "next/3 returns destination if distance <= speed" do
    destination = {1, 0}
    assert Position.next(@origin, destination, 1) == destination
  end

  test "next/3 returns a new position if distance > speed" do
    destination = {10, 0}
    assert Position.next(@origin, destination, 3) == {3, 0}
  end

  test "next/3 returns a position on the straight line between 2 positions" do
    from = {0, 1}
    destination = {10, 6}
    fx = fn x -> 0.5 * x + 1 end
    fy = fn y -> 2 * y - 2 end
    {x, y} = Position.next(from, destination, 3)

    assert fx.(x) == y
    assert fy.(y) == x
  end

  test "next/3 using angle returns a valid destination" do
    assert Position.next(@origin, Math.pi(), 10) == {-10, 0}
  end
end
