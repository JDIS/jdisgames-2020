defmodule Diep.Io.Gameloop do
  @moduledoc """
  Module that handles the time constraint of the server.
  It is responsible for generating iterations.
  """

  use GenServer
  alias Diep.Io.{ActionStorage, PerformanceMonitor, ScoreRepository, UsersRepository}
  alias Diep.IoWeb.Endpoint
  alias Diep.Io.Core.{Action, GameState}
  alias :erlang, as: Erlang
  require Logger

  # Client

  @doc """
    Game_time is the number of ticks the game will last.
  """
  @spec start_link(
          name: atom(),
          game_time: integer(),
          persistent?: boolean(),
          tick_rate: integer(),
          monitor_performance?: boolean()
        ) :: {:ok, pid()}
  def start_link(
        name: name,
        game_time: game_time,
        persistent?: persistent?,
        tick_rate: tick_rate,
        monitor_performance?: monitor_performance?
      ) do
    GenServer.start(
      __MODULE__,
      [
        name: name,
        game_time: game_time,
        persistent?: persistent?,
        tick_rate: tick_rate,
        monitor_performance?: monitor_performance?
      ],
      name: name
    )
  end

  @spec stop_game(atom()) :: :ok
  def stop_game(name), do: GenServer.call(name, :stop_game)

  @spec kill_game(atom()) :: :ok
  def kill_game(name), do: GenServer.stop(name)

  # Server (callbacks)

  @impl true
  def init(
        name: name,
        game_time: game_time,
        persistent?: persistent?,
        tick_rate: tick_rate,
        monitor_performance?: monitor_performance?
      ) do
    :ok = ActionStorage.init(name)
    init_game_state(name, game_time, persistent?, tick_rate, monitor_performance?)
  end

  @impl true
  def handle_call(:stop_game, _from, state) do
    {:reply, :ok, GameState.stop_loop_after_max_ticks(state)}
  end

  @impl true
  def handle_info(:reset_game, state) do
    :ok = save_scores(state)
    handle_reset_game(state)
  end

  @impl true
  def handle_info(:loop, state) do
    begin_time = Erlang.monotonic_time()
    elasped_time = GameState.calculate_elasped_time(state, begin_time)
    Logger.debug("looperoo took #{Erlang.convert_time_unit(elasped_time, :native, :millisecond)}ms")

    updated_state =
      state.tanks
      |> Map.keys()
      |> Enum.map(fn id -> ActionStorage.get_action(state.name, id) end)
      |> GameState.handle_players(state)
      |> GameState.handle_projectiles()
      |> GameState.handle_debris()
      |> GameState.handle_collisions()
      |> GameState.decrease_cooldowns()
      |> GameState.handle_tank_death()
      |> GameState.increase_ticks()
      |> GameState.add_time_correction(elasped_time)

    broadcast(updated_state)

    end_time = Erlang.monotonic_time()

    case GameState.in_progress?(updated_state) do
      true ->
        iteration_duration = end_time - begin_time
        if updated_state.monitor_performance?, do: PerformanceMonitor.store_gameloop_duration(iteration_duration)
        sleep_time = GameState.calculate_time_to_wait(updated_state, iteration_duration)
        Process.send_after(self(), :loop, sleep_time)

      false ->
        send(self(), :reset_game)
    end

    {:noreply, Map.put(updated_state, :last_time, begin_time)}
  end

  # Privates
  defp init_game_state(name, game_time, persistent?, tick_rate, monitor_performance?) do
    game_id = System.unique_integer()
    users = UsersRepository.list_users()
    # Initialize ActionStorage's content with empty actions for each user
    users |> Enum.each(fn user -> ActionStorage.store_action(name, Action.new(user.id)) end)

    if monitor_performance?, do: PerformanceMonitor.reset()

    Logger.info("Initialized gameloop #{game_id} with #{length(users)} users")
    send(self(), :loop)
    {:ok, GameState.new(name, users, game_time, game_id, persistent?, tick_rate, monitor_performance?)}
  end

  defp handle_reset_game(%{should_stop?: true} = state) do
    {:stop, :normal, state}
  end

  defp handle_reset_game(%{should_stop?: false} = state) do
    :ok = ActionStorage.reset(state.name)

    {:ok, new_state} =
      init_game_state(state.name, state.max_ticks, state.persistent?, state.tick_rate, state.monitor_performance?)

    {:noreply, new_state}
  end

  defp broadcast(state) do
    Endpoint.broadcast!("game_state", "new_state", state)
    if state.monitor_performance?, do: PerformanceMonitor.store_broadcast_time(Erlang.monotonic_time())
  end

  defp save_scores(%{persistent?: true} = state) do
    scores =
      Enum.map(state.tanks, fn {tank_id, tank} ->
        %{user_id: tank_id, score: tank.score, game_id: state.game_id}
      end)

    Enum.each(scores, fn score -> ScoreRepository.add_score(score) end)

    :ok
  end

  defp save_scores(_state), do: :ok
end
