defmodule DiepIO.ActionStorage do
  @moduledoc false

  alias :ets, as: Ets
  alias DiepIO.Core.Action
  require Logger

  @spec init(atom()) :: :ok
  def init(table_name) do
    Logger.debug("Initializing ActionStorage table with name #{table_name}")
    Ets.new(table_name, [:named_table, :public, write_concurrency: true])
    :ok
  end

  @spec reset(atom()) :: :ok
  def reset(table_name) do
    true = Ets.delete(table_name)
    init(table_name)
  end

  @spec store_action(atom(), Action.t()) :: true
  def store_action(table_name, action) do
    Ets.insert(table_name, {action.tank_id, action})
  end

  @spec pop_action(atom(), any()) :: Action.t() | nil
  def pop_action(table_name, tank_id) do
    case Ets.take(table_name, tank_id) do
      [{_tank_id, action}] -> action
      [] -> nil
    end
  end
end
