defmodule DiepIO.Core.Clock do
  @moduledoc """
    Handles the time aspect of the game.

    The clock ticks at a certain rate. Events can be registered using a frequency. The clock can then
    determine if an event is due to occur. It can also determine the amount of time until the next tick.

    clock_rate: The number of ticks in a second
    max_tick: The max number of ticks
    current_tick: The current clock tick
    events: A map of event_name => event_frequency
    corrections: A list of corrections the clock needs to consider when calculating the time until the next tick
  """

  alias :erlang, as: Erlang

  @derive {Jason.Encoder, only: [:current_tick, :max_tick]}
  defstruct [
    :clock_rate,
    :max_tick,
    current_tick: 0,
    last_time: 0,
    events: %{},
    corrections: []
  ]

  @type t :: %__MODULE__{
          clock_rate: number | :infinity,
          max_tick: integer,
          current_tick: integer,
          last_time: integer,
          events: %{required(any) => integer},
          corrections: [integer]
        }

  @spec new(number, integer, [Keyword.t()]) :: t()
  def new(clock_rate, max_tick, opts \\ []) do
    struct(
      %__MODULE__{
        clock_rate: clock_rate,
        max_tick: max_tick
      },
      opts
    )
  end

  @spec register(t(), any, integer) :: t()
  def register(clock, event_name, frequency) do
    %{clock | events: Map.put(clock.events, event_name, frequency)}
  end

  @spec due?(t(), any) :: boolean
  def due?(clock, event_name) do
    frequency = Map.get(clock.events, event_name, nil)
    check_if_due(clock.current_tick, frequency)
  end

  @spec restart(t()) :: t()
  def restart(clock, max_ticks \\ nil) do
    %{clock | current_tick: 0, max_tick: max_ticks || clock.max_tick}
  end

  @spec done?(t()) :: boolean
  def done?(clock), do: clock.current_tick >= clock.max_tick

  @spec tick(t()) :: t()
  def tick(clock), do: %{clock | current_tick: clock.current_tick + 1}

  @spec set_last_time(t(), integer) :: t()
  def set_last_time(clock, last_time) do
    %{clock | last_time: last_time}
  end

  @spec calculate_time_until_next_tick(t(), integer) :: integer
  def calculate_time_until_next_tick(clock, elapsed_time) do
    time_correction = calculate_correction(clock.corrections)

    (calculate_iteration_duration(clock.clock_rate) - elapsed_time - time_correction)
    |> max(0)
    |> Erlang.convert_time_unit(:native, :millisecond)
  end

  @spec add_time_correction(t(), integer()) :: t()
  def add_time_correction(%{corrections: corrections} = clock, elapsed_time)
      when length(corrections) >= 16 do
    add_time_correction(%{clock | corrections: Enum.drop(corrections, -1)}, elapsed_time)
  end

  def add_time_correction(%{corrections: corrections} = clock, elapsed_time) do
    correction = elapsed_time - calculate_iteration_duration(clock.clock_rate)
    %{clock | corrections: [correction | corrections]}
  end

  @spec calculate_elasped_time(t(), integer()) :: integer()
  def calculate_elasped_time(%{last_time: 0, clock_rate: clock_rate}, _now) do
    calculate_iteration_duration(clock_rate)
  end

  def calculate_elasped_time(%{last_time: last_time}, now), do: now - last_time

  # Privates
  defp check_if_due(_current_tick, nil), do: false
  defp check_if_due(current_tick, frequency), do: rem(current_tick, frequency) == 0

  defp calculate_iteration_duration(:infinity), do: 0

  defp calculate_iteration_duration(tick_rate) do
    Erlang.convert_time_unit(div(1000, tick_rate), :millisecond, :native)
  end

  defp calculate_correction([]), do: 0

  defp calculate_correction(corrections) do
    Kernel.floor(Enum.sum(corrections) / Enum.count(corrections))
  end
end
