defmodule Diep.IoWeb.AdminControllerTest do
  use Diep.IoWeb.ConnCase, async: false

  test "GET /admin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :index))

    assert html_response(conn, 200) =~ "ADMIN INDEX"
  end

  test "GET /admin/start starts the main game and /admin/kill kills it", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :start_game, ticks: "50"))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Started game, #"

    conn =
      build_conn()
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :kill_game))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Main game killed"
  end

  test "GET /admin/start starts the main game and /admin/stop stops it after game", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :start_game, ticks: "1"))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Started game, #"

    conn =
      build_conn()
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :stop_game))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Main game will stop after max ticks."

    Process.sleep(1000)
  end

  test "GET /admin returns a 401 on invalid creds", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("inval:id"))
      |> get(Routes.admin_path(conn, :index))

    assert response(conn, 401)
  end
end
