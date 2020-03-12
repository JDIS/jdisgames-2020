defmodule MonitorStatelessTest do
  use ExUnit.Case

  alias Diep.Io.Monitor

  setup do
    init_state = %{gameloop_times: []}
    [init_state: init_state]
  end

  test "init/1 should initialize the state correctly", %{init_state: init_state} do
    {:ok, state} = Monitor.init(:ok)
    assert state == init_state
  end

  test "add_gameloop cast should store the given time in state", %{init_state: init_state} do
    time = 10
    {:noreply, new_state} = Monitor.handle_cast({:add_gameloop, time}, init_state)
    assert new_state == %{gameloop_times: [time]}
  end

  test "get_gamelopp call should return the list of gameloop times", %{init_state: init_state} do
    {:reply, times, _} = Monitor.handle_call({:get_gameloop}, :ok, init_state)
    assert times == []
  end

  test "get_gameloop call should not update the state", %{init_state: init_state} do
    {:reply, _, new_state} = Monitor.handle_call({:get_gameloop}, :ok, init_state)
    assert new_state == init_state
  end
end

defmodule MonitorStatefulTest do
  use ExUnit.Case, async: false

  alias Diep.Io.Monitor

  setup do
    start_supervised(Monitor)
    [times: [10, 20], average: 15, std_dev: 5]
  end

  test "store_gameloop_time/1 store the given time" do
    time = 10
    Monitor.store_gameloop_time(time)

    times = Monitor.get_gameloop_times()
    assert Enum.any?(times, &Kernel.==(&1, time))
  end

  test "get_gameloop_stats/0 returns the correct average", %{times: times, average: average} do
    Enum.each(times, &Monitor.store_gameloop_time/1)

    {calculated_average, _} = Monitor.get_gameloop_stats()
    assert calculated_average == average
  end

  test "get_gameloop_stats/0 returns the correct standard deviation", %{times: times, std_dev: std_dev} do
    Enum.each(times, &Monitor.store_gameloop_time/1)

    {_, calculated_std_dev} = Monitor.get_gameloop_stats()
    assert calculated_std_dev == std_dev
  end

  test "get_gameloop_times/0 returns the whole list of stored times", %{times: times} do
    Enum.each(times, &Monitor.store_gameloop_time/1)

    assert Enum.sort(times) == Enum.sort(Monitor.get_gameloop_times())
  end
end
