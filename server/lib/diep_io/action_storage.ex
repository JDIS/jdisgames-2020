defmodule Diep.Io.ActionStorage do
  @moduledoc false

  alias :ets, as: Ets
  alias Diep.Io.Core.Action
  require Logger

  @table_name :action_table

  @spec init(atom()) :: :ok
  def init(table_name \\ @table_name) do
    Logger.debug("Initializing ActionStorage table with name #{table_name}")
    Ets.new(table_name, [:named_table, :public, write_concurrency: true])
    :ok
  end

  @spec store_action(atom(), any, Action.t()) :: true
  def store_action(table_name \\ @table_name, tank_id, action) do
    Ets.insert(table_name, {tank_id, action})
  end

  @spec get_action(atom(), any) :: Action.t()
  def get_action(table_name \\ @table_name, tank_id) do
    [{_tank_id, action}] = Ets.lookup(table_name, tank_id)
    action
  end
end
