defmodule Diep.Io.Upgrades.MaxHP do
  @moduledoc false

  alias Diep.Io.Core.Tank
  alias Diep.Io.Upgrades

  @behaviour Upgrades.Upgrade

  @upgrades [10, 20, 30]
  @upgrade_prices [100, 200, 300]

  @impl Upgrades.Upgrade
  @spec max_level() :: non_neg_integer
  def max_level, do: Enum.count(@upgrades)

  @impl Upgrades.Upgrade
  @spec prices() :: [non_neg_integer]
  def prices, do: @upgrade_prices

  @impl Upgrades.Upgrade
  @spec price(non_neg_integer) :: non_neg_integer
  def price(level), do: Enum.at(prices(), level)

  @impl Upgrades.Upgrade
  @spec apply(Tank.t()) :: Tank.t()
  def apply(tank) do
    current_level = Upgrades.level(tank, __MODULE__)
    hp_boost = Enum.at(@upgrades, current_level + 1)

    tank
    |> Tank.increment_max_hp(hp_boost)
    |> Upgrades.register_upgrade(__MODULE__)
  end
end
