defmodule DiepIOSchemas.GameParams do
  @moduledoc """
  Game params represent the various parameters that influnce a game.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          number_of_ticks: integer(),
          max_debris_count: integer(),
          max_debris_generation_rate: float(),
          score_multiplier: float()
        }

  @primary_key {:game_name, :string, []}

  schema "game_params" do
    field(:number_of_ticks, :integer)
    field(:max_debris_count, :integer)
    field(:max_debris_generation_rate, :float)
    field(:score_multiplier, :float)
  end

  @spec default_params() :: t()
  def default_params do
    %__MODULE__{
      number_of_ticks: 2000,
      max_debris_count: 400,
      max_debris_generation_rate: 0.15,
      score_multiplier: 1.0
    }
  end
end
