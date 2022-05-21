defmodule RealTimeTest do
  use DiepIO.DataCase, async: false

  @moduletag :RT
  @moduletag timeout: 335_000

  alias DiepIO.Core.{Action, Clock}
  alias DiepIO.{ActionStorage, Gameloop, PerformanceMonitor, Repo, UsersRepository}
  alias DiepIOSchemas.User
  alias :rand, as: Rand

  @game_time 1000
  @game_name :what_a_name

  setup do
    :ok = 1..40 |> Enum.each(fn i -> UsersRepository.create_user(%{name: "User#{i}"}) end)
    users = Repo.all(User)

    {:ok, _pid} = start_supervised({Task, fn -> randomize_actions_infinite(users) end})

    :ok
  end

  test "max game loop iteration time should be under 333ms" do
    start_and_wait_until_completion(get_gameloop_spec(1000))

    {_average, _std_dev, max} = stats = PerformanceMonitor.get_gameloop_stats()
    assert max <= 333

    write_file("max_iteration_time", stats)
  end

  test "standard deviation of time between state updates should be under 10ms" do
    start_and_wait_until_completion(get_gameloop_spec(15))

    {_average, std_dev, _max} = stats = PerformanceMonitor.get_broadcast_stats()
    assert std_dev <= 10

    write_file("broadcast_std_dev", stats)
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

  defp write_file(filename, {average, std_dev, max}) do
    badges_location = Application.fetch_env!(:diep_io, :custom_badges_location)
    File.mkdir(badges_location)
    file_path = "#{badges_location}/#{filename}.json"
    file_content = "{\"average\":#{average},\"std_dev\":#{std_dev},\"max\":#{max}}"
    File.write!(file_path, file_content)
  end

  defp get_gameloop_spec(tick_rate) do
    [
      name: @game_name,
      is_ranked: false,
      monitor_performance?: true,
      clock: Clock.new(tick_rate, @game_time)
    ]
  end
end
