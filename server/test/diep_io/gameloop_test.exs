defmodule GameloopTest do
  use Diep.Io.DataCase, async: false

  alias Diep.Io.{ActionStorage, Gameloop, PerformanceMonitor, ScoreRepository, UsersRepository}
  alias Diep.Io.Core.{Action, Clock, GameState}
  alias Diep.Io.Users.Score
  alias :ets, as: Ets

  setup do
    tank_id = 1
    game_time = 10
    game_name = :test_game
    tick_rate = 3
    monitor_performance? = false
    clock = Clock.new(tick_rate, game_time)

    {:ok,
     tank_id: tank_id,
     game_name: game_name,
     tick_rate: tick_rate,
     monitor_performance?: monitor_performance?,
     clock: clock}
  end

  test "A gameloop loop with a valid destination moves the desired tank", %{
    tank_id: tank_id,
    game_name: game_name,
    clock: clock
  } do
    start_supervised!(
      {Gameloop,
       [
         name: game_name,
         is_ranked: false,
         monitor_performance?: false,
         clock: clock
       ]}
    )

    ActionStorage.store_action(game_name, Action.new(tank_id, %{destination: {0, 0}}))

    state = GameState.new(game_name, [%{id: tank_id, name: "some_name"}], 0, false, false, clock)

    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.tanks[tank_id].position != state.tanks[tank_id].position
  end

  describe "init/1" do
    test "initialize Gameloop properly", %{
      game_name: game_name,
      monitor_performance?: monitor_performance?,
      clock: clock
    } do
      is_ranked = false

      assert {:ok,
              %GameState{
                name: game_name,
                is_ranked: is_ranked,
                clock: clock
              }} =
               Gameloop.init(
                 name: game_name,
                 is_ranked: is_ranked,
                 monitor_performance?: monitor_performance?,
                 clock: clock
               )

      assert is_reference(Ets.whereis(game_name))

      assert_received :loop
    end
  end

  describe "handle_info/2" do
    test ":loop increments tick when not over", %{game_name: game_name, clock: clock} do
      is_ranked = false

      {:noreply, new_state} = Gameloop.handle_info(:loop, GameState.new(game_name, [], 1, is_ranked, false, clock))

      assert new_state.clock.current_tick == 1

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :loop
    end

    test ":loop sends :reset_game when over", %{game_name: game_name} do
      is_ranked = false
      clock = Clock.new(3, 10, current_tick: 11)

      Gameloop.handle_info(:loop, GameState.new(game_name, [], 1, is_ranked, false, clock))

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :reset_game
    end

    test ":loop does not broadcast every time", %{game_name: game_name} do
      {:ok, _pid} = start_supervised({PerformanceMonitor, :millisecond})
      max_tick = 10
      client_frequency = 5
      clock = Clock.new(:infinity, max_tick) |> Clock.register(:client_tick, client_frequency)

      :ok =
        start_and_wait_until_completion(
          name: game_name,
          is_ranked: false,
          monitor_performance?: true,
          clock: clock
        )

      client_update_count = length(PerformanceMonitor.get_broadcast_times())
      assert(client_update_count == max_tick / client_frequency)
    end

    test ":reset_game saves the scores when is_is_ranked true", %{game_name: game_name, clock: clock} do
      user_name = "some_name"
      game_id = 1

      {:ok, user} = UsersRepository.create_user(%{name: user_name})

      tank_id = user.id

      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} =
               Gameloop.handle_info(
                 :reset_game,
                 GameState.new(game_name, [%{id: tank_id, name: user_name}], game_id, true, false, clock)
               )

      assert [
               %Score{
                 game_id: game_id,
                 user_id: tank_id,
                 score: 0
               }
             ] = ScoreRepository.get_scores()
    end

    test ":reset_game doesn't save the scores when is_is_ranked false", %{game_name: game_name, clock: clock} do
      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} =
               Gameloop.handle_info(:reset_game, GameState.new(game_name, [], 1, false, false, clock))

      assert [] = ScoreRepository.get_scores()
    end

    test ":reset_game sends {:stop, :normal, state} when should_stop? is true", %{game_name: game_name, clock: clock} do
      ActionStorage.init(game_name)

      game_state =
        GameState.new(game_name, [], 1, false, false, clock)
        |> GameState.stop_loop_after_max_ticks()

      assert {:stop, :normal, %GameState{}} = Gameloop.handle_info(:reset_game, game_state)
    end
  end

  # Starts the gameloop and returns :ok when it end
  defp start_and_wait_until_completion(opts) do
    {:ok, pid} = Gameloop.start_link(opts)

    Gameloop.stop_game(Keyword.get(opts, :name))

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
  end
end
