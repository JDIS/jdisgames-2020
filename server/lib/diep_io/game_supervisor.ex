defmodule Diep.Io.GameSupervisor do
  @moduledoc """
  The game supervisor is responsible to supervise each game.
  It can dynamically start the main game or private games.
  """

  use DynamicSupervisor

  alias Diep.Io.Core.Clock
  alias Diep.Io.Gameloop

  @main_game_name :main_game

  # Client
  @spec start_link([]) :: {:ok, pid()}
  def start_link([]), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  @spec start_main_game(non_neg_integer()) :: {:ok, pid()}
  def start_main_game(game_time), do: start_game(@main_game_name, true, game_time, 3, true)

  @spec stop_main_game :: :ok
  def stop_main_game, do: Gameloop.stop_game(@main_game_name)

  @spec kill_main_game :: :ok
  def kill_main_game, do: Gameloop.kill_game(@main_game_name)

  # Server (callbacks)
  def init([]), do: DynamicSupervisor.init(strategy: :one_for_one)

  # Privates
  defp start_game(name, persistent?, game_time, tick_rate, monitor_performance?) do
    spec =
      {Gameloop,
       name: name,
       persistent?: persistent?,
       monitor_performance?: monitor_performance?,
       clock: Clock.new(tick_rate, game_time)}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
