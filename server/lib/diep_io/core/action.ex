defmodule Diep.Io.Core.Action do
  @moduledoc false

  @enforce_keys [:tank_id]
  defstruct [:tank_id, :destination, :target, :purchase]

  @type position :: {integer, integer}
  @type t :: %__MODULE__{
          tank_id: any,
          destination: position | nil,
          target: position | nil,
          purchase: term | nil
        }

  @spec new(any, destination: position, target: position, purchase: term) :: t()
  def new(tank_id, opts \\ []), do: struct(%__MODULE__{tank_id: tank_id}, opts)

  @spec has_destination?(t()) :: boolean
  def has_destination?(action), do: action.destination != nil

  @spec has_target?(t()) :: boolean
  def has_target?(action), do: action.target != nil

  @spec has_purchase?(t()) :: boolean
  def has_purchase?(action), do: action.purchase != nil
end
