defmodule DiepIO.Core.HotZone do
  @moduledoc false

  alias DiepIO.Core.Entity
  alias DiepIO.Core.Position

  @default_radius 500

  @derive Jason.Encoder
  @enforce_keys [:position]
  defstruct [:position]

  @type t :: %__MODULE__{
          position: Position.t()
        }

  defimpl Entity do
    alias DiepIO.Core.HotZone

    @spec get_position(HotZone.t()) :: Position.t()
    def get_position(hot_zone), do: hot_zone.position

    @spec get_radius(HotZone.t()) :: integer()
    def get_radius(_hot_zone), do: HotZone.default_radius()

    @spec get_body_damage(HotZone.t()) :: integer()
    def get_body_damage(_hot_zone), do: 0
  end

  @spec new(Position.t()) :: t()
  def new(position) do
    %__MODULE__{position: position}
  end

  @spec default_radius() :: integer()
  def default_radius, do: @default_radius
end
