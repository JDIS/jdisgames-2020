defmodule DiepIOWeb.ScoreboardAuthPlug do
  @moduledoc false

  alias DiepIO.GlobalParamsRepository
  alias DiepIOWeb.AuthenticationPlug

  def init(opts), do: opts

  def call(conn, _opts) do
    if GlobalParamsRepository.get_params().enable_scoreboard_auth do
      AuthenticationPlug.call(conn, AuthenticationPlug.init(nil))
    else
      conn
    end
  end
end
