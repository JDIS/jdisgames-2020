defmodule ActionTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Action

  @tank_id "Tank"
  @action_details [destination: {0, 0}, target: {0, 0}, purchase: Diep.Io.Upgrades.MaxHP]

  setup do
    [default_action: Action.new(@tank_id), complete_action: Action.new(@tank_id, @action_details)]
  end

  test "has_destination?/1 determines if the action has a destination", %{
    default_action: default,
    complete_action: complete
  } do
    assert Action.has_destination?(default) == false
    assert Action.has_destination?(complete) == true
  end

  test "has_target?/1 determines if the action has a target", %{
    default_action: default,
    complete_action: complete
  } do
    assert Action.has_target?(default) == false
    assert Action.has_target?(complete) == true
  end

  test "has_purchase?/1 determines if the action has a purchase", %{
    default_action: default,
    complete_action: complete
  } do
    assert Action.has_purchase?(default) == false
    assert Action.has_purchase?(complete) == true
  end
end
