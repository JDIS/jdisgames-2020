defmodule Diep.Io.Upgrades do
  @moduledoc false

  @spec register_upgrade(Diep.Io.Tank.t(), term) :: Diep.Io.Tank.t()
  def register_upgrade(tank, upgrade) do
    %{tank | upgrades: Map.update!(tank.upgrades, upgrade, fn level -> level + 1 end)}
  end

  @spec level(Diep.Io.Tank.t(), term) :: non_neg_integer
  def level(tank, upgrade) do
    Map.get(tank.upgrades, upgrade)
  end
end
