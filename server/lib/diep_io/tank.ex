defmodule Diep.Io.Tank do
  @moduledoc false

  @default_hp 100
  @default_speed 10

  @enforce_keys [:name, :current_hp, :max_hp, :speed]
  defstruct [:name, :max_hp, :current_hp, :speed, experience: 0]

  @type t :: %__MODULE__{
          name: String.t(),
          max_hp: integer,
          current_hp: integer,
          speed: integer,
          experience: integer
        }

  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{name: name, current_hp: @default_hp, max_hp: @default_hp, speed: @default_speed}
  end

  @spec is_dead?(t) :: boolean
  def is_dead?(%__MODULE__{} = tank), do: tank.current_hp <= 0

  @spec is_alive?(t()) :: boolean
  def is_alive?(%__MODULE__{} = tank), do: !is_dead?(tank)

  @spec heal(t(), integer) :: t()
  def heal(%__MODULE__{current_hp: current_hp, max_hp: max_hp} = tank, amount)
      when current_hp + amount <= max_hp,
      do: add_to_value(tank, :current_hp, amount)

  def heal(%__MODULE__{} = tank, _amount),
    do: set_value(tank, :current_hp, tank.max_hp)

  @spec hit(t(), integer) :: t()
  def hit(%__MODULE__{} = tank, amount), do: remove_from_value(tank, :current_hp, amount)

  @spec add_experience(t(), integer) :: t()
  def add_experience(%__MODULE__{} = tank, amount), do: add_to_value(tank, :experience, amount)

  @spec default_hp() :: integer
  def default_hp, do: @default_hp

  @spec default_speed() :: integer
  def default_speed, do: @default_speed

  defp add_to_value(%__MODULE__{} = tank, field, amount),
    do: Map.update!(tank, field, &(&1 + amount))

  defp remove_from_value(%__MODULE__{} = tank, field, amount),
    do: add_to_value(tank, field, -amount)

  defp set_value(%__MODULE__{} = tank, field, value), do: Map.replace!(tank, field, value)
end
