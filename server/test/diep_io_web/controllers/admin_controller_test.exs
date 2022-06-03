defmodule DiepIOWeb.AdminControllerTest do
  use DiepIOWeb.ConnCase, async: false

  setup do
    %{game_name: "main_game"}
  end

  test "GET /admin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :index))

    assert html_response(conn, 200) =~ "<div id=\"admin\">"
  end

  test "GET /admin/start starts the required game and /admin/kill kills it", %{
    conn: conn,
    game_name: game_name
  } do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :start_game, ticks: "50", game_name: game_name))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Started game &quot;#{game_name}&quot;: #"

    conn =
      build_conn()
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :kill_game, game_name: game_name))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Game &quot;#{game_name}&quot; killed"
  end

  test "GET /admin/start starts the required game and /admin/stop stops it after game", %{
    conn: conn,
    game_name: game_name
  } do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :start_game, ticks: "1", game_name: game_name))

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Started game &quot;#{game_name}&quot;: #"

    conn =
      build_conn()
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :stop_game), %{game_name: game_name})

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Game &quot;#{game_name}&quot; will stop after max ticks."

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
