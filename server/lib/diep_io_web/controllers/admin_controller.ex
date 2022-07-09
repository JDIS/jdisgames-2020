defmodule DiepIOWeb.AdminController do
  use DiepIOWeb, :controller

  alias DiepIO.GameParamsRepository
  alias DiepIO.GameSupervisor

  def index(conn, _params) do
    main_game_params = GameParamsRepository.get_game_params("main_game")
    secondary_game_params = GameParamsRepository.get_game_params("secondary_game")

    render(conn, "index.html", main_game_params: main_game_params, secondary_game_params: secondary_game_params)
  end

  def start_game(conn, %{"game_name" => game_name}) do
    {:ok, pid} = GameSupervisor.start_game(game_name)

    finish_call(conn, "Started game \"#{game_name}\": #{inspect(pid)}")
  end

  def save_params(conn, params) do
    update_game_params(params)

    finish_call(conn, "Saved parameters for game \"#{params["game_name"]}\"")
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

  defp update_game_params(params) do
    game_name = params["game_name"]
    number_of_ticks = String.to_integer(params["ticks"])
    max_debris_count = parse_integer(params["max_debris_count"]) || 400
    max_debris_generation_rate = parse_float(params["max_debris_generation_rate"]) || 0.15
    score_multiplier = parse_float(params["score_multiplier"]) || 1.0

    GameParamsRepository.save_game_params(
      game_name,
      number_of_ticks,
      max_debris_count,
      max_debris_generation_rate,
      score_multiplier
    )
  end
end
