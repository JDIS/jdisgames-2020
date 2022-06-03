defmodule ActionStorageTest do
  use ExUnit.Case, async: false

  alias DiepIO.ActionStorage
  alias DiepIO.Core.Action
  alias :ets, as: Ets

  setup do
    tank_id = 1
    [table_name: :test, action: Action.new(tank_id), tank_id: tank_id]
  end

  test "init/1 initializes ActionStorage table", %{table_name: table_name} do
    assert Ets.whereis(table_name) == :undefined
    :ok = ActionStorage.init(table_name)
    assert Ets.whereis(table_name) != :undefined
  end

  test "reset/1 resets ActionStorage table", %{
    table_name: table_name,
    action: action,
    tank_id: tank_id
  } do
    :ok = ActionStorage.init(table_name)
    true = ActionStorage.store_action(table_name, action)

    :ok = ActionStorage.reset(table_name)

    assert ActionStorage.pop_action(table_name, tank_id) == nil
  end

  test "store_action/2 stores the given action for the given player", %{
    table_name: table_name,
    action: action,
    tank_id: tank_id
  } do
    :ok = ActionStorage.init(table_name)

    true = ActionStorage.store_action(table_name, action)
    assert hd(Ets.lookup(table_name, tank_id)) == {tank_id, action}
  end

  test "pop_action/2 pops the stored action for the given player", %{
    table_name: table_name,
    action: action,
    tank_id: tank_id
  } do
    :ok = ActionStorage.init(table_name)

    true = Ets.insert(table_name, {tank_id, action})
    assert ActionStorage.pop_action(table_name, tank_id) == action
    assert ActionStorage.pop_action(table_name, tank_id) == nil
  end

  test "pop_action/2 returns nil when no stored action", %{
    table_name: table_name,
    tank_id: tank_id
  } do
    :ok = ActionStorage.init(table_name)

    assert ActionStorage.pop_action(table_name, tank_id) == nil
  end
end
