defmodule Diep.IoWeb.PageControllerTest do
  use Diep.IoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Action tests"
  end

  test "GET /spectate", %{conn: conn} do
    conn = get(conn, "/spectate")
    assert html_response(conn, 200) =~ "<div id=\"app\">"
  end
end
