defmodule DiepIO.Gameloop do
  @moduledoc """
  Module that handles the time constraint of the server.
  It is responsible for generating iterations.
  """

  use GenServer
  alias DiepIO.{ActionStorage, GameParamsRepository, PubSub, ScoreRepository, UsersRepository}
  alias DiepIO.Performance.Monitor, as: PerformanceMonitor
  alias DiepIO.Core.{Clock, GameState}
  alias DiepIO.GameParams
  alias :erlang, as: Erlang
  require Logger

  @client_tick_frequency 5

  # Client

  @doc """
    Game_time is the number of ticks the game will last.
  """
  @spec start_link(
          name: atom(),
          is_ranked: boolean(),
          monitor_performance?: boolean(),
          tick_rate: integer()
        ) :: {:ok, pid()}
  def start_link(
        name: name,
        is_ranked: is_ranked,
        monitor_performance?: monitor_performance?,
        tick_rate: tick_rate
      ) do
    GenServer.start(
      __MODULE__,
      [
        name: name,
        is_ranked: is_ranked,
        monitor_performance?: monitor_performance?,
        tick_rate: tick_rate
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
        is_ranked: is_ranked,
        monitor_performance?: monitor_performance?,
        tick_rate: tick_rate
      ) do
    :ok = ActionStorage.init(name)
    game_params = fetch_game_params(name)
    clock = Clock.new(tick_rate, game_params.number_of_ticks)

    init_game_state(name, is_ranked, monitor_performance?, game_params, clock)
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
    elasped_time = Clock.calculate_elasped_time(state.clock, begin_time)

    Logger.debug("#{state.name}: looperoo took #{Erlang.convert_time_unit(elasped_time, :native, :millisecond)}ms")

    actions =
      state.tanks
      |> Map.keys()
      |> Enum.map(fn id -> ActionStorage.pop_action(state.name, id) end)

    updated_state =
      state
      |> GameState.handle_tanks(actions)
      |> GameState.handle_hp_regen()
      |> GameState.handle_projectiles()
      |> GameState.handle_debris()
      |> GameState.handle_collisions()
      |> GameState.decrease_cooldowns()
      |> GameState.handle_tank_death()
      |> GameState.increase_ticks()
      |> GameState.add_time_correction(elasped_time)

    if Clock.due?(updated_state.clock, :client_tick), do: broadcast(updated_state)

    end_time = Erlang.monotonic_time()

    case GameState.in_progress?(updated_state) do
      true ->
        iteration_duration = end_time - begin_time

        if updated_state.monitor_performance?,
          do: PerformanceMonitor.store_gameloop_duration(iteration_duration)

        sleep_time = Clock.calculate_time_until_next_tick(updated_state.clock, iteration_duration)
        Process.send_after(self(), :loop, sleep_time)

      false ->
        send(self(), :reset_game)
    end

    {:noreply, Map.put(updated_state, :last_time, begin_time)}
  end

  def client_tick_frequency, do: @client_tick_frequency

  # Privates
  defp init_game_state(name, is_ranked, monitor_performance?, game_params, clock) do
    game_id = System.unique_integer()
    users = UsersRepository.list_users()
    clock = register_clock_events(clock)

    if monitor_performance?, do: PerformanceMonitor.reset()

    Logger.info("Initialized gameloop #{game_id} with #{length(users)} users")
    send(self(), :loop)
    {:ok, GameState.new(name, users, game_id, is_ranked, monitor_performance?, clock, game_params)}
  end

  defp handle_reset_game(%{should_stop?: true} = state) do
    {:stop, :normal, state}
  end

  defp handle_reset_game(%{should_stop?: false} = state) do
    :ok = ActionStorage.reset(state.name)
    game_params = fetch_game_params(state.name)

    {:ok, new_state} =
      init_game_state(
        state.name,
        state.is_ranked,
        state.monitor_performance?,
        game_params,
        Clock.restart(state.clock, game_params.number_of_ticks)
      )

    {:noreply, new_state}
  end

  defp broadcast(state) do
    PubSub.broadcast!("new_state:#{state.name}", {:new_state, state})

    if state.monitor_performance?,
      do: PerformanceMonitor.store_broadcasted_at(Erlang.monotonic_time())
  end

  defp save_scores(%{is_ranked: true} = state) do
    state.tanks
    |> Enum.map(fn {tank_id, tank} ->
      %{user_id: tank_id, score: tank.score, game_id: state.game_id}
    end)
    |> Enum.each(fn score -> ScoreRepository.add_score(score) end)

    :ok
  end

  defp save_scores(_state), do: :ok

  defp register_clock_events(clock) do
    clock
    |> Clock.register(:client_tick, @client_tick_frequency)
  end

  defp fetch_game_params(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> fetch_game_params()
  end

  defp fetch_game_params(name) do
    GameParamsRepository.get_game_params(name) || GameParams.default_params()
  end
end
