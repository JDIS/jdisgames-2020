defmodule ActionStorageTest do
  use ExUnit.Case, async: true

  alias Diep.Io.ActionStorage
  alias Diep.Io.Core.Action
  alias :ets, as: Ets

  @tank_id 1
  @action Action.new(@tank_id)
  @table_name :test

  setup do
    ActionStorage.init(@table_name)
    [table_name: @table_name]
  end

  test "store_action/3 stores the given action for the given player", %{table_name: table_name} do
    ActionStorage.store_action(table_name, @tank_id, @action)
    assert hd(Ets.lookup(table_name, @tank_id)) == {@tank_id, @action}
  end

  test "get_action/2 returns the stored action for the given player", %{table_name: table_name} do
    Ets.insert(table_name, {@tank_id, @action})
    assert ActionStorage.get_action(table_name, @tank_id) == @action
  end
end
