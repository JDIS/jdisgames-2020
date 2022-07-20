defmodule DiepIOWeb.PageControllerTest do
  @moduledoc false

  alias DiepIO.GameParams
  alias DiepIO.GameParamsRepository

  use DiepIOWeb.ConnCase

  test "GET /", %{conn: conn} do
    GameParamsRepository.save_game_params(
      "main_game",
      GameParams.default_params()
    )

    conn = get(conn, Routes.page_path(conn, :index))
    assert html_response(conn, 200) =~ "JDIS Games 2022"
  end

  test "GET /spectate", %{conn: conn} do
    conn = get(conn, Routes.page_path(conn, :spectate), %{game_name: "main_game"})
    assert html_response(conn, 200) =~ "<div id=\"app\">"
  end

  test "GET /scoreboard", %{conn: conn} do
    conn = get(conn, Routes.page_path(conn, :scoreboard))
    assert html_response(conn, 200) =~ "<div id=\"scoreboard\">"
  end
end
