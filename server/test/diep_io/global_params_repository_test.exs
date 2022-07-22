defmodule DiepIO.GlobalParamsRepositoryTest do
  use DiepIO.DataCase

  alias DiepIO.GlobalParamsRepository
  alias DiepIO.Repo
  alias DiepIOSchemas.GlobalParams

  test "get_params/1 returns the params" do
    params = GlobalParamsRepository.get_params()

    assert params.enable_scoreboard_auth == false
  end

  test "save_params/1 saves the params" do
    GlobalParamsRepository.save_params(true)

    [params] = Repo.all(GlobalParams)

    assert params.enable_scoreboard_auth == true
  end
end
