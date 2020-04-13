defmodule RealTimeTest do
  use Diep.Io.DataCase, async: false

  @moduletag :RT
  @moduletag timeout: 335_000

  alias Diep.Io.Core.{Action, Clock}
  alias Diep.Io.{ActionStorage, Gameloop, PerformanceMonitor, Repo, UsersRepository}
  alias Diep.Io.Users.User
  alias :rand, as: Rand

  @game_time 1000

  setup do
    :ok = 1..40 |> Enum.each(fn i -> UsersRepository.create_user(%{name: "User#{i}"}) end)
    users = Repo.all(User)

    {:ok, _pid} = start_supervised({Task, fn -> randomize_actions_infinite(users) end})
    {:ok, _pid} = start_supervised({PerformanceMonitor, :millisecond})

    :ok
  end

  test "max game loop iteration time should be under 333ms" do
    {:ok, _pid} = start_supervised({Gameloop, get_gameloop_spec(1000)})

    wait_for_game_end()
    {_average, _std_dev, max} = stats = PerformanceMonitor.get_gameloop_stats()
    assert max <= 333

    write_file("max_iteration_time", stats)
  end

  test "standard deviation of time between state updates should be under 10ms" do
    {:ok, _pid} = start_supervised({Gameloop, get_gameloop_spec(3)})

    wait_for_game_end()
    {_average, std_dev, _max} = stats = PerformanceMonitor.get_broadcast_stats()
    assert std_dev <= 10

    write_file("broadcast_std_dev", stats)
  end

  defp wait_for_game_end do
    count = PerformanceMonitor.get_gameloop_count()

    if count < @game_time - 1 do
      Process.sleep(100)
      wait_for_game_end()
    end
  end

  defp randomize_actions_infinite(users) do
    Enum.each(users, fn user ->
      destination = {Rand.uniform(1000), Rand.uniform(1000)}
      target = {Rand.uniform(1000), Rand.uniform(1000)}
      upgrade = Enum.random([:speed, :fire_rate, :projectile_damage, :max_hp, :body_damage])
      action = Action.new(user.id, destination: destination, target: target, purchase: upgrade)
      ActionStorage.store_action(action)
    end)

    Process.sleep(10)
    randomize_actions_infinite(users)
  end

  defp write_file(filename, {average, std_dev, max}) do
    badges_location = System.get_env("CUSTOM_BADGES_LOCATION", "./badges")
    File.mkdir(badges_location)
    file_path = "#{badges_location}/#{filename}.json"
    file_content = "{\"average\":#{average},\"std_dev\":#{std_dev},\"max\":#{max}}"
    File.write!(file_path, file_content)
  end

  defp get_gameloop_spec(tick_rate) do
    [
      name: :what_a_name,
      persistent?: false,
      monitor_performance?: true,
      clock: Clock.new(tick_rate, @game_time)
    ]
  end
end
