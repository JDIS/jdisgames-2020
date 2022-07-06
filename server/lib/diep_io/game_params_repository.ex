defmodule DiepIO.GameParamsRepository do
  @moduledoc """
  The GameParamsRepositoryContext
  """

  import Ecto.Changeset

  alias DiepIO.Repo

  alias DiepIOSchemas.GameParams

  @spec get_game_params(String.t()) :: GameParams.t() | nil
  def get_game_params(game_name) do
    Repo.get(GameParams, game_name)
  end

  @spec save_game_params(String.t(), integer(), integer(), float(), float()) :: :ok
  def save_game_params(game_name, number_of_ticks, max_debris_count, max_debris_generation_rate, score_multiplier) do
    %GameParams{}
    |> cast(
      %{
        game_name: game_name,
        number_of_ticks: number_of_ticks,
        max_debris_count: max_debris_count,
        max_debris_generation_rate: max_debris_generation_rate,
        score_multiplier: score_multiplier
      },
      [:game_name, :number_of_ticks, :max_debris_count, :max_debris_generation_rate, :score_multiplier]
    )
    |> validate_required([
      :game_name,
      :number_of_ticks,
      :max_debris_count,
      :max_debris_generation_rate,
      :score_multiplier
    ])
    |> Repo.insert!(on_conflict: :replace_all, conflict_target: :game_name)

    :ok
  end
end
