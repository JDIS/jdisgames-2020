defmodule GameloopTest do
  use Diep.Io.DataCase, async: false

  alias Diep.Io.{ActionStorage, Gameloop, ScoreRepository, UsersRepository}
  alias Diep.Io.Core.{Action, GameState}
  alias Diep.Io.Users.Score
  alias :ets, as: Ets

  setup do
    tank_id = 1
    game_time = 10
    game_name = :test_game

    {:ok, tank_id: tank_id, game_time: game_time, game_name: game_name}
  end

  test "A gameloop loop with a valid destination moves the desired tank", %{
    tank_id: tank_id,
    game_time: game_time,
    game_name: game_name
  } do
    start_supervised!({Gameloop, [name: game_name, game_time: game_time, persistent?: false]})

    ActionStorage.store_action(game_name, Action.new(tank_id, %{destination: {0, 0}}))

    state = GameState.new(game_name, [%{id: tank_id, name: "some_name"}], game_time, 0, false)

    {:noreply, result} = Gameloop.handle_info(:loop, state)
    assert result.tanks[tank_id].position != state.tanks[tank_id].position
  end

  describe "init/1" do
    test "initialize Gameloop properly", %{game_name: game_name, game_time: game_time} do
      persistent? = false

      assert {:ok,
              %GameState{
                name: game_name,
                max_ticks: game_time,
                persistent?: persistent?
              }} = Gameloop.init(name: game_name, game_time: game_time, persistent?: persistent?)

      assert is_reference(Ets.whereis(game_name))

      assert_received :loop
    end
  end

  describe "handle_info/2" do
    test ":loop increments tick when not over", %{game_name: game_name} do
      persistent? = false

      assert {:noreply,
              %GameState{
                ticks: 1
              }} = Gameloop.handle_info(:loop, GameState.new(game_name, [], 1, 1, persistent?))

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :loop
    end

    test ":loop sends :reset_game when over", %{game_name: game_name} do
      persistent? = false

      assert {:noreply,
              %GameState{
                ticks: 1
              }} = Gameloop.handle_info(:loop, GameState.new(game_name, [], 0, 1, persistent?))

      # Waiting for message to be sent
      :ok = Process.sleep(333)

      assert_received :reset_game
    end

    test ":reset_game saves the scores when is_persistent? true", %{game_name: game_name} do
      user_name = "some_name"
      game_id = 1

      {:ok, user} = UsersRepository.create_user(%{name: user_name})

      tank_id = user.id

      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} =
               Gameloop.handle_info(
                 :reset_game,
                 GameState.new(game_name, [%{id: tank_id, name: user_name}], 0, game_id, true)
               )

      assert [
               %Score{
                 game_id: game_id,
                 user_id: tank_id,
                 score: 0
               }
             ] = ScoreRepository.get_scores()
    end

    test ":reset_game doesn't save the scores when is_persistent? false", %{game_name: game_name} do
      ActionStorage.init(game_name)

      assert {:noreply, %GameState{}} = Gameloop.handle_info(:reset_game, GameState.new(game_name, [], 0, 1, false))

      assert [] = ScoreRepository.get_scores()
    end

    test ":reset_game sends {:stop, :normal, state} when should_stop? is true", %{game_name: game_name} do
      ActionStorage.init(game_name)

      game_state =
        GameState.new(game_name, [], 0, 1, false)
        |> GameState.stop_loop_after_max_ticks()

      assert {:stop, :normal, %GameState{}} = Gameloop.handle_info(:reset_game, game_state)
    end
  end
end
