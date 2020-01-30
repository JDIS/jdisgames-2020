defmodule Diep.Io.Upgrades do
  @moduledoc false

  alias Diep.Io.Core.Tank

  @spec register_upgrade(Tank.t(), term) :: Tank.t()
  def register_upgrade(tank, upgrade) do
    %{tank | upgrades: Map.update!(tank.upgrades, upgrade, fn level -> level + 1 end)}
  end

  @spec level(Tank.t(), term) :: non_neg_integer
  def level(tank, upgrade) do
    Map.get(tank.upgrades, upgrade)
  end
end
