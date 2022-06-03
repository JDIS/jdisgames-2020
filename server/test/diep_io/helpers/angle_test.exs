defmodule AngleTest do
  use ExUnit.Case, async: true

  alias DiepIO.Helpers.Angle
  alias :math, as: Math

  test "degree/2 gives angles in degree" do
    assert Angle.degree({0, 0}, {10, 0}) == 0.0
    assert Angle.degree({0, 0}, {0, 10}) == 90.0
    assert Angle.degree({0, 0}, {-10, 0}) == 180.0
    assert Angle.degree({0, 0}, {0, -10}) == -90.0
    assert Angle.degree({0, 0}, {2, 5}) == 68.19859051364818
  end

  test "radian/2 gives angles in radian" do
    assert Angle.radian({0, 0}, {10, 0}) == 0
    assert Angle.radian({0, 0}, {0, 10}) == Math.pi() / 2
    assert Angle.radian({0, 0}, {-10, 0}) == Math.pi()
    assert Angle.radian({0, 0}, {0, -10}) == -Math.pi() / 2
  end
end
