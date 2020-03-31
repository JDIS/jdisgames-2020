defmodule Diep.IoWeb.AdminControllerTest do
  use Diep.IoWeb.ConnCase, async: false

  test "GET /admin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get("/admin")

    assert html_response(conn, 200) =~ "ADMIN INDEX"
  end

  test "GET /admin/start starts the main game and /admin/stop stops it", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get("/admin/start", ticks: 50)

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Started game, #"

    conn =
      build_conn()
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get("/admin/stop")

    assert "/admin" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~ "Main game stopped"
  end

  test "GET /admin returns a 401 on invalid creds", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("inval:id"))
      |> get("/admin")

    assert response(conn, 401)
  end
end
