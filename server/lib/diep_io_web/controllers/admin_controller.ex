defmodule Diep.IoWeb.AdminController do
  use Diep.IoWeb, :controller

  alias Diep.Io.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def start_game(conn, %{"ticks" => ticks} = _params) do
    {:ok, pid} =
      ticks
      |> String.to_integer()
      |> GameSupervisor.start_main_game()

    conn
    |> put_flash(:info, "Started game, #{inspect(pid)}")
    |> redirect(to: Routes.admin_path(conn, :index))
  end

  def stop_game(conn, _params) do
    :ok = GameSupervisor.stop_main_game()

    conn
    |> put_flash(:info, "Main game will stop after max ticks.")
    |> redirect(to: Routes.admin_path(conn, :index))
  end

  def kill_game(conn, _params) do
    :ok = GameSupervisor.kill_main_game()

    conn
    |> put_flash(:info, "Main game killed")
    |> redirect(to: Routes.admin_path(conn, :index))
  end
end
