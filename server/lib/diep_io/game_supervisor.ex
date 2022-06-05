defmodule DiepIO.GameSupervisor do
  @moduledoc """
  The game supervisor is responsible to supervise each game.
  It can dynamically start the main game or private games.
  """

  use DynamicSupervisor

  alias DiepIO.Core.Clock
  alias DiepIO.Gameloop

  @main_game_name :main_game
  @secondary_game_name :secondary_game
  @default_tick_rate 15

  # Client
  @spec start_link([]) :: {:ok, pid()}
  def start_link([]), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  @spec start_game(non_neg_integer(), String.t()) :: {:ok, pid()}
  def start_game(game_time, "main_game") do
    start_game(@main_game_name, true, game_time, @default_tick_rate, true)
  end

  def start_game(game_time, "secondary_game") do
    start_game(@secondary_game_name, false, game_time, @default_tick_rate, false)
  end

  @spec stop_game(String.t()) :: :ok
  def stop_game("main_game"), do: Gameloop.stop_game(@main_game_name)
  def stop_game("secondary_game"), do: Gameloop.stop_game(@secondary_game_name)

  @spec kill_game(String.t()) :: :ok
  def kill_game("main_game"), do: Gameloop.kill_game(@main_game_name)
  def kill_game("secondary_game"), do: Gameloop.kill_game(@secondary_game_name)

  # Server (callbacks)
  def init([]), do: DynamicSupervisor.init(strategy: :one_for_one)

  # Privates
  defp start_game(name, is_ranked, game_time, tick_rate, monitor_performance?) do
    spec =
      {Gameloop,
       name: name,
       is_ranked: is_ranked,
       monitor_performance?: monitor_performance?,
       clock: Clock.new(tick_rate, game_time)}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def default_tick_rate(), do: @default_tick_rate
end
