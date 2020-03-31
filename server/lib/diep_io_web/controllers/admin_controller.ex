defmodule Diep.IoWeb.AdminController do
  use Diep.IoWeb, :controller

  alias Diep.Io.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def start_game(conn, %{"ticks" => ticks} = _params) do
    {:ok, pid} = GameSupervisor.start_main_game(ticks)

    conn
    |> put_flash(:info, "Started game, #{inspect(pid)}")
    |> redirect(to: "/admin")
  end

  def stop_game(conn, _params) do
    :ok = GameSupervisor.stop_main_game()

    conn
    |> put_flash(:info, "Main game stopped")
    |> redirect(to: "/admin")
  end
end
