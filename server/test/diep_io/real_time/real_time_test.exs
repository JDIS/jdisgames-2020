defmodule RealTimeTest do
  use DiepIO.DataCase, async: false

  @moduletag :RT
  @moduletag timeout: 335_000

  alias DiepIO.Core.{Action, Clock}
  alias DiepIO.{ActionStorage, Gameloop, Repo, UsersRepository}
  alias DiepIO.Performance.Monitor, as: PerformanceMonitor
  alias DiepIOSchemas.User
  alias :rand, as: Rand

  @game_params %{
    max_debris_count: 400,
    max_debris_generation_rate: 0.15,
    score_multiplier: 1.0
  }
  @game_time 1000
  @game_name :what_a_name
  @number_of_users 200

  setup do
    :ok = 1..@number_of_users |> Enum.each(fn i -> UsersRepository.create_user(%{name: "User#{i}"}) end)
    users = Repo.all(User)

    {:ok, _pid} = start_supervised({Task, fn -> randomize_actions_infinite(users) end})

    :ok
  end

  test "max game loop iteration time should be under 333ms" do
    start_and_wait_until_completion(get_gameloop_spec(1000))

    {:ok, stats} = PerformanceMonitor.get_gameloop_stats()
    assert stats.max <= 333
  end

  test "standard deviation of time between state updates should be under 10ms" do
    start_and_wait_until_completion(get_gameloop_spec(15))

    {:ok, stats} = PerformanceMonitor.get_broadcast_stats()
    assert stats.std_dev <= 10
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

  defp randomize_actions_infinite(users) do
    Enum.each(users, fn user ->
      destination = {Rand.uniform(1000), Rand.uniform(1000)}
      target = {Rand.uniform(1000), Rand.uniform(1000)}
      upgrade = Enum.random([:speed, :fire_rate, :projectile_damage, :max_hp, :body_damage])
      action = Action.new(user.id, destination: destination, target: target, purchase: upgrade)
      ActionStorage.store_action(@game_name, action)
    end)

    Process.sleep(10)
    randomize_actions_infinite(users)
  end

  defp get_gameloop_spec(tick_rate) do
    [
      name: @game_name,
      is_ranked: false,
      monitor_performance?: true,
      game_params: @game_params,
      clock: Clock.new(tick_rate, @game_time)
    ]
  end
end
