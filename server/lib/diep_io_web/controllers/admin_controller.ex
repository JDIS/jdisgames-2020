defmodule DiepIOWeb.AdminController do
  use DiepIOWeb, :controller

  alias DiepIO.GameSupervisor

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def start_game(conn, %{"ticks" => ticks, "game_name" => game_name} = params) do
    game_params = %{
      max_debris_count: parse_integer(params["max_debris_count"]) || 400,
      max_debris_generation_rate: parse_float(params["max_debris_generation_rate"]) || 0.15,
      score_multiplier: parse_float(params["score_multiplier"]) || 1
    }

    {:ok, pid} =
      ticks
      |> String.to_integer()
      |> GameSupervisor.start_game(game_params, game_name)

    finish_call(conn, "Started game \"#{game_name}\": #{inspect(pid)}")
  end

  def stop_game(conn, %{"game_name" => game_name} = _params) do
    :ok = GameSupervisor.stop_game(game_name)
    finish_call(conn, "Game \"#{game_name}\" will stop after max ticks.")
  end

  def kill_game(conn, %{"game_name" => game_name} = _params) do
    :ok = GameSupervisor.kill_game(game_name)
    finish_call(conn, "Game \"#{game_name}\" killed.")
  end

  defp finish_call(conn, message) do
    conn
    |> put_flash(:info, message)
    |> redirect(to: Routes.admin_path(conn, :index))
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(num), do: String.to_integer(num)

  defp parse_float(nil), do: nil

  defp parse_float(num) do
    case Float.parse(num) do
      {float, ""} -> float
    end
  end
end
