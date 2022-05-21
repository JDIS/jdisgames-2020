defmodule ActionTest do
  use ExUnit.Case, async: true

  alias DiepIO.Core.{Action, Position}

  test "new/1 creates an empty action" do
    tank_id = "test_tank"

    assert %Action{
             tank_id: tank_id,
             destination: nil,
             target: nil,
             purchase: nil
           } == Action.new(tank_id)
  end

  test "new/2 creates a specific action" do
    tank_id = "test_tank"
    expected_destination = Position.new(3, 3)
    expected_target = Position.new(3, 3)

    assert %Action{
             tank_id: tank_id,
             destination: expected_destination,
             target: expected_target,
             purchase: nil
           } == Action.new(tank_id, destination: expected_destination, target: expected_target)
  end
end
