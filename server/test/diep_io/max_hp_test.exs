defmodule MaxHPTest do
  use ExUnit.Case, async: true

  alias Diep.Io.{Tank, Upgrades}
  alias Upgrades.MaxHP

  setup do
    [tank: Tank.new("Tank")]
  end

  test "apply/1 increases :max_hp", %{tank: tank} do
    assert MaxHP.apply(tank).max_hp > Tank.default_hp()
  end

  test "apply/1 increses the upgrade level", %{tank: tank} do
    leveled_up_tank = MaxHP.apply(tank)

    assert Upgrades.level(leveled_up_tank, MaxHP) == Upgrades.level(tank, MaxHP) + 1
  end

  test "there is a price for every level" do
    assert Enum.count(MaxHP.prices()) == MaxHP.max_level()
  end

  test "price/1 matches prices/0" do
    prices =
      Enum.reduce(0..(MaxHP.max_level() - 1), [], fn current_level, prices ->
        prices ++ [MaxHP.price(current_level)]
      end)

    assert prices == MaxHP.prices()
  end
end
