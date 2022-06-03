defmodule DiepIO.Core.Action do
  @moduledoc false

  alias DiepIO.Core.Position

  @enforce_keys [:tank_id]
  defstruct [:tank_id, :destination, :target, :purchase]

  @type position :: {integer, integer}
  @type t :: %__MODULE__{
          tank_id: any,
          destination: Position.t() | nil,
          target: Position.t() | nil,
          purchase: term | nil
        }

  @spec new(any, destination: Position.t(), target: Position.t(), purchase: term) :: t()
  def new(tank_id, opts \\ []), do: struct(%__MODULE__{tank_id: tank_id}, opts)
end
