defmodule Diep.Io.Core.GameState do
  @moduledoc false

  alias Diep.Io.Core.Tank

  defstruct [:in_progress, :tanks]

  @type t :: %__MODULE__{
          in_progress: boolean(),
          tanks: [Tank.t()]
        }

  @spec new([String.t()]) :: t()
  def new(tank_names) do
    %__MODULE__{
      in_progress: false,
      tanks: initialize_tanks(tank_names)
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game_state), do: %{game_state | in_progress: true}

  @spec stop_game(t()) :: t()
  def stop_game(game_state), do: %{game_state | in_progress: false}

  defp initialize_tanks(tank_names), do: tank_names |> Enum.map(&Tank.new/1)
end
