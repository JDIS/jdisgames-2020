defmodule GameloopTest do
  use DiepIO.DataCase, async: false

  alias DiepIO.{ActionStorage, Gameloop, ScoreRepository, UsersRepository, GameParamsRepository}
  alias DiepIO.Performance.Monitor, as: PerformanceMonitor
  alias DiepIO.Core.{Action, Clock, GameState}
  alias DiepIOSchemas.Score
  alias :ets, as: Ets

  setup do
    game_params = %{
      max_debris_count: 400,
      max_debris_generation_rate: 0.15,
      score_multiplier: 1,
      number_of_ticks: 10
    }

    tank_id = 1
    game_name = :test_game
    tick_rate = 3
    monitor_performance? = false
    clock = Clock.new(tick_rate, game_params.number_of_ticks)

    :ok =
      GameParamsRepository.save_game_params(
        Atom.to_string(game_name),
        10,
        game_params.max_debris_count,
        game_params.max_debris_generation_rate,
        game_params.score_multiplier
      )

    {
      :ok,
      tank_id: tank_id,
      game_name: game_name,
      tick_rate: tick_rate,
      monitor_performance?: monitor_performance?,
      game_params: game_params,
      clock: clock,
      tick_rate: tick_rate
    }
  end

  test "A gameloop loop with a valid destination moves the desired tank", %{
    tank_id: tank_id,
    game_name: game_name,
    game_params: game_params,
    clock: clock,
    tick_rate: tick_rate
  } do
    start_supervised!(
      {Gameloop,
       [
         name: game_name,
         is_ranked: false,
         monitor_performance?: false,
         tick_rate: tick_rate
       ]}
    )

    ActionStorage.store_action(game_name, Action.new(tank_id, %{destination: {0, 0}}))

    state = GameState.new(game_name, [%{id: tank_id, name: "some_name"}], 0, false, false, clock, game_params)

    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.tanks[tank_id].position != state.tanks[tank_id].position
  end

  describe "init/1" do
    test "initialize Gameloop properly", %{
      game_name: game_name,
      monitor_performance?: monitor_performance?,
      tick_rate: tick_rate
    } do
      is_ranked = false

      assert {:ok,
              %GameState{
                name: game_name
              }} =
               Gameloop.init(
                 name: game_name,
                 is_ranked: is_ranked,
                 monitor_performance?: monitor_performance?,
                 tick_rate: tick_rate
               )

      assert is_reference(Ets.whereis(game_name))

      assert_received :loop
    end
  end

  describe "handle_info/2" do
    test ":loop increments tick when not over", %{game_name: game_name, clock: clock, game_params: game_params} do
      is_ranked = false

      {:noreply, new_state} =
        Gameloop.handle_info(:loop, GameState.new(game_name, [], 1, is_ranked, false, clock, game_params))

      assert new_state.clock.current_tick == 1

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :loop
    end

    test ":loop sends :reset_game when over", %{game_name: game_name, game_params: game_params} do
      is_ranked = false
      clock = Clock.new(3, 10, current_tick: 11)

      Gameloop.handle_info(:loop, GameState.new(game_name, [], 1, is_ranked, false, clock, game_params))

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :reset_game
    end

    @tag timeout: 10000
    test ":loop does not broadcast every time", %{game_name: game_name, tick_rate: tick_rate, game_params: game_params} do
      :ok =
        start_and_wait_until_completion(
          name: game_name,
          is_ranked: false,
          monitor_performance?: true,
          tick_rate: tick_rate
        )

      client_update_count = length(PerformanceMonitor.get_broadcast_delays())
      assert client_update_count + 1 == game_params.number_of_ticks / 5
    end

    test ":reset_game saves the scores when is_is_ranked true", %{
      game_name: game_name,
      game_params: game_params,
      clock: clock
    } do
      user_name = "some_name"
      game_id = 1

      {:ok, user} = UsersRepository.create_user(%{name: user_name})

      tank_id = user.id

      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} =
               Gameloop.handle_info(
                 :reset_game,
                 GameState.new(
                   game_name,
                   [%{id: tank_id, name: user_name}],
                   game_id,
                   true,
                   false,
                   clock,
                   game_params
                 )
               )

      assert [
               %Score{
                 score: 0
               }
             ] = ScoreRepository.get_scores()
    end

    test ":reset_game doesn't save the scores when is_is_ranked false", %{
      game_name: game_name,
      game_params: game_params,
      clock: clock
    } do
      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} =
               Gameloop.handle_info(
                 :reset_game,
                 GameState.new(game_name, [], 1, false, false, clock, game_params)
               )

      assert [] = ScoreRepository.get_scores()
    end

    test ":reset_game sends {:stop, :normal, state} when should_stop? is true", %{
      game_name: game_name,
      game_params: game_params,
      clock: clock
    } do
      ActionStorage.init(game_name)

      game_state =
        GameState.new(game_name, [], 1, false, false, clock, game_params)
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
