defmodule DiepIOWeb.AdminControllerTest do
  @moduledoc false

  use DiepIOWeb.ConnCase, async: false

  alias DiepIO.GameParams
  alias DiepIO.GameParamsRepository
  alias DiepIO.UpgradeParams

  setup do
    GameParamsRepository.save_game_params(
      "main_game",
      GameParams.new(%{
        number_of_ticks: 1,
        max_debris_count: 200,
        max_debris_generation_rate: 0.5,
        score_multiplier: 2.5,
        upgrade_params: %{
          speed: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          max_hp: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          body_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          fire_rate: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          hp_regen: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_time_to_live: %UpgradeParams{base_value: 10, upgrade_rate: 0.5}
        }
      })
    )

    %{game_name: "main_game"}
  end

  test "GET /admin render the app container", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
      |> get(Routes.admin_path(conn, :index))

    assert html_response(conn, 200) =~ "<div id=\"admin\""
  end

  test "GET /admin renders the game params data attributes for the main game", %{conn: conn} do
    GameParamsRepository.save_game_params(
      "main_game",
      GameParams.new(%{
        number_of_ticks: 100,
        max_debris_count: 200,
        max_debris_generation_rate: 0.5,
        score_multiplier: 2.5,
        upgrade_params: %{
          speed: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          max_hp: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          body_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          fire_rate: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          hp_regen: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_time_to_live: %UpgradeParams{base_value: 10, upgrade_rate: 0.5}
        }
      })
    )

    conn =
      conn
      |> authorize_conn()
      |> get(Routes.admin_path(conn, :index))

    assert html_response(conn, 200) =~
             "<div id=\"mainGameParams\" data-number-of-ticks=\"100\" data-max-debris-count=\"200\" data-max-debris-generation-rate=\"0.5\" data-score-multiplier=\"2.5\""
  end

  test "GET /admin renders the game params data attributes for the secondary game", %{conn: conn} do
    GameParamsRepository.save_game_params(
      "secondary_game",
      GameParams.new(%{
        number_of_ticks: 100,
        max_debris_count: 200,
        max_debris_generation_rate: 0.5,
        score_multiplier: 2.5,
        upgrade_params: %{
          speed: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          max_hp: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          body_damage: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          fire_rate: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          hp_regen: %UpgradeParams{base_value: 10, upgrade_rate: 0.5},
          projectile_time_to_live: %UpgradeParams{base_value: 10, upgrade_rate: 0.5}
        }
      })
    )

    conn =
      conn
      |> authorize_conn()
      |> get(Routes.admin_path(conn, :index))

    assert html_response(conn, 200) =~
             "<div id=\"secondaryGameParams\" data-number-of-ticks=\"100\" data-max-debris-count=\"200\" data-max-debris-generation-rate=\"0.5\" data-score-multiplier=\"2.5\""
  end

  test "GET /admin/save saves the game parameters", %{conn: conn, game_name: game_name} do
    conn
    |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
    |> get(
      Routes.admin_path(conn, :save_params,
        ticks: "15",
        game_name: game_name,
        max_debris_count: 10,
        max_debris_generation_rate: 0.5,
        score_multiplier: 2.0
      )
    )

    game_params = GameParamsRepository.get_game_params(game_name)

    assert game_params.number_of_ticks == 15
    assert game_params.max_debris_count == 10
    assert game_params.max_debris_generation_rate == 0.5
    assert game_params.score_multiplier == 2.0
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

    conn = call_kill(conn, game_name)

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

  defp call_kill(conn, game_name) do
    build_conn()
    |> put_req_header("authorization", "Basic " <> Base.encode64("admin:admin"))
    |> get(Routes.admin_path(conn, :kill_game, game_name: game_name))
  end

  defp authorize_conn(conn), do: put_req_header(conn, "authorization", "Basic " <> Base.encode64("admin:admin"))
end
