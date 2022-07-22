defmodule DiepIO.GlobalParamsRepository do
  @moduledoc false

  alias DiepIO.Repo
  alias DiepIOSchemas.GlobalParams

  @spec get_params() :: GlobalParams.t()
  def get_params, do: Repo.one!(GlobalParams)

  def save_params(enable_scoreboard_auth) do
    Repo.update_all(GlobalParams, set: [enable_scoreboard_auth: enable_scoreboard_auth])

    :ok
  end
end
