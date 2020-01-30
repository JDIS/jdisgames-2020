defmodule Diep.Io.Tank do
  @moduledoc false

  alias Diep.Io.Upgrades

  @default_hp 100
  @default_speed 10
  @default_upgrades %{Diep.Io.Upgrades.MaxHP => 0}

  @enforce_keys [:name, :current_hp, :max_hp, :speed]
  defstruct [:name, :max_hp, :current_hp, :speed, experience: 0, upgrades: @default_upgrades]

  @type t :: %__MODULE__{
          name: String.t(),
          max_hp: integer,
          current_hp: integer,
          speed: integer,
          experience: integer
        }

  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{
      name: name,
      current_hp: @default_hp,
      max_hp: @default_hp,
      speed: @default_speed
    }
  end

  @spec is_dead?(t) :: boolean
  def is_dead?(tank), do: tank.current_hp <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(tank), do: !is_dead?(tank)

  @spec heal(t(), integer) :: t()
  def heal(tank, amount) do
    case tank.current_hp + amount <= tank.max_hp do
      true -> add_to_value(tank, :current_hp, amount)
      false -> set_value(tank, :current_hp, tank.max_hp)
    end
  end

  @spec hit(t(), integer) :: t()
  def hit(tank, amount), do: remove_from_value(tank, :current_hp, amount)

  @spec add_experience(t(), integer) :: t()
  def add_experience(tank, amount), do: add_to_value(tank, :experience, amount)

  @spec increment_max_hp(t(), integer) :: t()
  def increment_max_hp(tank, amount) do
    tank |> add_to_value(:max_hp, amount) |> heal(amount)
  end

  @spec buy_upgrade(t(), term) :: t()
  def buy_upgrade(tank, upgrade) do
    level = Upgrades.level(tank, upgrade)
    price = upgrade.price(level)

    case tank.experience >= price do
      true -> tank |> remove_from_value(:experience, price) |> upgrade.apply()
      false -> tank
    end
  end

  @spec default_hp() :: integer
  def default_hp, do: @default_hp

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  @spec default_upgrades() :: map
  def default_upgrades, do: @default_upgrades

  defp add_to_value(tank, field, amount),
    do: Map.update!(tank, field, &(&1 + amount))

  defp remove_from_value(tank, field, amount),
    do: add_to_value(tank, field, -amount)

  defp set_value(tank, field, value), do: Map.replace!(tank, field, value)
end
