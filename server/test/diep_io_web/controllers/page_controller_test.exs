defmodule Diep.IoWeb.PageControllerTest do
  use Diep.IoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<h1>JDIS Games 2020</h1>"
  end

  test "GET /spectate", %{conn: conn} do
    conn = get(conn, "/spectate")
    assert html_response(conn, 200) =~ "<div id=\"app\">"
  end

  test "GET /scoreboard", %{conn: conn} do
    conn = get(conn, "/scoreboard")
    assert html_response(conn, 200) =~ "<div id=\"scoreboard\">"
  end
end
