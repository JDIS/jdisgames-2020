defmodule PerformanceMonitorStatelessTest do
  use ExUnit.Case

  alias Diep.Io.PerformanceMonitor

  setup do
    init_state = %{gameloop_times: [], gameloop_count: 0, time_unit: :native, broadcast_times: []}
    [init_state: init_state]
  end

  test "init/1 should initialize the state correctly", %{init_state: init_state} do
    time_unit = Map.get(init_state, :time_unit)
    {:ok, state} = PerformanceMonitor.init([time_unit])
    assert state == init_state
  end

  test "add_gameloop cast should store the given time in state", %{init_state: init_state} do
    time = 10
    {:noreply, new_state} = PerformanceMonitor.handle_cast({:add_gameloop, time}, init_state)
    assert new_state.gameloop_times == [time]
  end

  test "get_gamelopp call should return the list of gameloop durations", %{init_state: init_state} do
    expected_times = [5, 10, 20, 35]
    state = %{init_state | gameloop_times: expected_times}
    {:reply, times, _} = PerformanceMonitor.handle_call({:get_gameloop}, :ok, state)
    assert times == expected_times
  end

  test "get_gameloop call should not update the state", %{init_state: init_state} do
    {:reply, _, new_state} = PerformanceMonitor.handle_call({:get_gameloop}, :ok, init_state)
    assert new_state == init_state
  end

  test "add_broadcast cast should store the given time in state", %{init_state: init_state} do
    time = 10
    {:noreply, new_state} = PerformanceMonitor.handle_cast({:add_broadcast, time}, init_state)
    assert new_state.broadcast_times == [time]
  end

  test "get_broadcast call should return the list of broadcast times", %{init_state: init_state} do
    expected_times = [5, 10, 20, 35]
    state = %{init_state | broadcast_times: expected_times}
    {:reply, times, _} = PerformanceMonitor.handle_call({:get_broadcast}, :ok, state)
    assert times == expected_times
  end

  test "get_broadcast call should not update the state", %{init_state: init_state} do
    {:reply, _, new_state} = PerformanceMonitor.handle_call({:get_broadcast}, :ok, init_state)
    assert new_state == init_state
  end

  test "reset cast should return an empty state", %{init_state: init_state} do
    state = %{init_state | gameloop_count: 0}
    {:noreply, reset_state} = PerformanceMonitor.handle_cast({:reset}, state)
    assert reset_state == init_state
  end
end

defmodule PerformanceMonitorStatefulTest do
  use ExUnit.Case, async: false

  alias Diep.Io.PerformanceMonitor

  setup do
    start_supervised({PerformanceMonitor, :native})

    [
      gameloop_durations: [10, 20],
      gameloop_stats: {15, 5, 20},
      broadcast_times: [5, 15, 35],
      broadcast_stats: {15, 5, 20}
    ]
  end

  test "store_gameloop_duration/1 store the given duration" do
    duration = 10
    PerformanceMonitor.store_gameloop_duration(duration)

    durations = PerformanceMonitor.get_gameloop_durations()
    assert Enum.any?(durations, &Kernel.==(&1, duration))
  end

  test "get_gameloop_stats/0 returns the correct average",
       %{gameloop_durations: durations, gameloop_stats: {average, _, _}} do
    Enum.each(durations, &PerformanceMonitor.store_gameloop_duration/1)

    {calculated_average, _, _} = PerformanceMonitor.get_gameloop_stats()
    assert calculated_average == average
  end

  test "get_gameloop_stats/0 returns the correct standard deviation",
       %{gameloop_durations: durations, gameloop_stats: {_, std_dev, _}} do
    Enum.each(durations, &PerformanceMonitor.store_gameloop_duration/1)

    {_, calculated_std_dev, _} = PerformanceMonitor.get_gameloop_stats()
    assert calculated_std_dev == std_dev
  end

  test "get_gameloop_stats/0 returns the correct maximum",
       %{gameloop_durations: durations, gameloop_stats: {_, _, max}} do
    Enum.each(durations, &PerformanceMonitor.store_gameloop_duration/1)

    {_, _, calculated_max} = PerformanceMonitor.get_gameloop_stats()
    assert calculated_max == max
  end

  test "get_gameloop_durations/0 returns the whole list of stored times", %{gameloop_durations: durations} do
    Enum.each(durations, &PerformanceMonitor.store_gameloop_duration/1)

    assert Enum.sort(durations) == Enum.sort(PerformanceMonitor.get_gameloop_durations())
  end

  test "store_broadcast_time/1 store the given time" do
    time = 10
    PerformanceMonitor.store_broadcast_time(time)

    times = PerformanceMonitor.get_broadcast_times()
    assert Enum.any?(times, &Kernel.==(&1, time))
  end

  test "get_broadcast_stats/0 returns the correct average",
       %{broadcast_times: times, broadcast_stats: {average, _, _}} do
    Enum.each(times, &PerformanceMonitor.store_broadcast_time/1)

    {calculated_average, _, _} = PerformanceMonitor.get_broadcast_stats()
    assert calculated_average == average
  end

  test "get_broadcast_stats/0 returns the correct standard deviation",
       %{broadcast_times: times, broadcast_stats: {_, std_dev, _}} do
    Enum.each(times, &PerformanceMonitor.store_broadcast_time/1)

    {_, calculated_std_dev, _} = PerformanceMonitor.get_broadcast_stats()
    assert calculated_std_dev == std_dev
  end

  test "get_broadcast_stats/0 returns the correct maximum",
       %{broadcast_times: times, broadcast_stats: {_, _, max}} do
    Enum.each(times, &PerformanceMonitor.store_broadcast_time/1)

    {_, _, calculated_max} = PerformanceMonitor.get_broadcast_stats()
    assert calculated_max == max
  end

  test "get_broadcast_times/0 returns the whole list of stored times", %{broadcast_times: times} do
    Enum.each(times, &PerformanceMonitor.store_broadcast_time/1)

    assert Enum.sort(times) == Enum.sort(PerformanceMonitor.get_broadcast_times())
  end

  test "reset/0 resets the monitor's state", %{gameloop_durations: [duration | _rest]} do
    PerformanceMonitor.store_gameloop_duration(duration)
    PerformanceMonitor.reset()

    assert PerformanceMonitor.get_gameloop_count() == 0
    assert PerformanceMonitor.get_gameloop_durations() == []
    assert PerformanceMonitor.get_broadcast_times() == []
  end
end
