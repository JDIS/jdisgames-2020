defmodule ClockTest do
  use ExUnit.Case, async: true

  alias Diep.Io.Core.Clock
  alias :erlang, as: Erlang

  setup do
    [clock: Clock.new(5, 69)]
  end

  test "new/3 creates a new clock" do
    assert %Clock{
             clock_rate: 5,
             max_tick: 69,
             current_tick: 42,
             events: %{}
           } == Clock.new(5, 69, current_tick: 42)
  end

  test "register/3 adds an event to the clock", %{clock: clock} do
    assert Clock.register(clock, :event, 5).events == %{:event => 5}
  end

  test "due?/2 returns false if the event does not exist", %{clock: clock} do
    assert !Map.has_key?(clock.events, :event)
    assert !Clock.due?(clock, :event)
  end

  test "due?/2 returns false if current_tick % frequency != 0" do
    Clock.new(5, 69, current_tick: 1)
    |> Clock.register(:event, 2)
    |> Clock.due?(:event)
    |> refute()
  end

  test "due?/2 returns true if current_tick % frequency == 0" do
    Clock.new(5, 69, current_tick: 5)
    |> Clock.register(:event, 5)
    |> Clock.due?(:event)
    |> assert()
  end

  test "restart/1 resets the current_tick to 0" do
    clock = Clock.new(5, 69, current_tick: 42)

    assert Clock.restart(clock) == %{clock | current_tick: 0}
  end

  test "done?/1 returns true if the max_tick is reached" do
    Clock.new(5, 69, current_tick: 70)
    |> Clock.done?()
    |> assert()
  end

  test "done?/1 returns false if the max_tick is not reached" do
    Clock.new(5, 69)
    |> Clock.done?()
    |> refute()
  end

  test "calculate_time_until_next_tick/2 returns the correct result" do
    tick_rate = 10
    elapsed_time_ms = 10
    elapsed_time = Erlang.convert_time_unit(elapsed_time_ms, :millisecond, :native)
    expected = div(1000, tick_rate) - elapsed_time_ms

    Clock.new(tick_rate, 69)
    |> Clock.calculate_time_until_next_tick(elapsed_time)
    |> Kernel.==(expected)
    |> assert()
  end

  test "calculate_time_until_next_tick/2 returns 0 if elapsed_time is greater than time of tick" do
    tick_rate = 10
    elapsed_time_ms = div(1000, tick_rate) + 1
    elapsed_time = Erlang.convert_time_unit(elapsed_time_ms, :millisecond, :native)

    Clock.new(tick_rate, 69)
    |> Clock.calculate_time_until_next_tick(elapsed_time)
    |> Kernel.==(0)
    |> assert()
  end
end
