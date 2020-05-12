defmodule Diep.Io.PerformanceMonitor do
  @moduledoc """
    Monitors the performance of the application with regards to our real time constraints.

    There are two main aspects that we monitor:
    * The amount of time that a single gameloop iteration takes to execute.
    At the time of writing, this should never exceed 333ms.
    * The delay between the state updates that are send to the client.
    At the time of writing, the standard deviation of these should never exceed 10ms.


    The performance critical modules should store their relevant data in the monitor through the `store*` functions.
    Statistics on this data can later be queried through the `get_*_stats` functions. Statistics are calculated on every query.
  """

  use GenServer
  alias :erlang, as: Erlang
  alias :math, as: Math
  alias :telemetry, as: Telemetry

  @telemetry_prefix [:game, :performance]

  def start_link(time_unit), do: GenServer.start(__MODULE__, [time_unit], name: __MODULE__)

  @spec store_gameloop_duration(integer()) :: :ok
  def store_gameloop_duration(iteration_time), do: GenServer.cast(__MODULE__, {:add_gameloop, iteration_time})

  @spec get_gameloop_stats :: {float(), float(), float()} | {:error, String.t()}
  def get_gameloop_stats, do: GenServer.call(__MODULE__, {:get_gameloop}) |> calculate_stats()

  @spec get_gameloop_durations :: [integer()]
  def get_gameloop_durations, do: GenServer.call(__MODULE__, {:get_gameloop})

  @spec get_gameloop_count :: integer()
  def get_gameloop_count, do: GenServer.call(__MODULE__, {:get_gameloop_count})

  @spec store_broadcast_time(integer()) :: :ok
  def store_broadcast_time(time), do: GenServer.cast(__MODULE__, {:add_broadcast, time})

  @spec get_broadcast_stats :: {float(), float(), float()} | {:error, String.t()}
  def get_broadcast_stats do
    case GenServer.call(__MODULE__, {:get_broadcast}) |> calculate_stats() do
      {_, std_dev, _} = stats ->
        Telemetry.execute(@telemetry_prefix, %{broadcast_time_std_dev: std_dev}, %{})
        stats

      {:error, err} ->
        {:error, err}
    end
  end

  @spec get_broadcast_times :: [integer()]
  def get_broadcast_times, do: GenServer.call(__MODULE__, {:get_broadcast})

  @spec reset :: :ok
  def reset, do: GenServer.cast(__MODULE__, {:reset})

  defp calculate_stats([]), do: {:error, "No data recorded"}

  defp calculate_stats(times) do
    times_length = length(times)

    average = Enum.sum(times) / times_length

    std_dev =
      times
      |> Enum.map(&Kernel.-(&1, average))
      |> Enum.map(&Math.pow(&1, 2))
      |> Enum.sum()
      |> Kernel./(times_length)
      |> Math.sqrt()

    max = Enum.max(times)

    {average, std_dev, max}
  end

  # Server callbacks

  @impl true
  def init([time_unit]) do
    {:ok, get_initial_state(time_unit)}
  end

  @impl true
  def handle_cast({:add_gameloop, iteration_time}, state) do
    Telemetry.execute(@telemetry_prefix, %{iteration_duration: iteration_time}, %{})

    target_unit = Map.get(state, :time_unit)

    iteration_time = Erlang.convert_time_unit(iteration_time, :native, target_unit)

    updated_state =
      state
      |> Map.update!(:gameloop_times, fn times -> [iteration_time | times] end)
      |> Map.update!(:gameloop_count, &(&1 + 1))

    {:noreply, updated_state}
  end

  @doc """
    Stores the difference between the latest broadcast time and the previous broadcast time
    in state. The first broadcast time is compared against itself, meaning that the first stored
    diff will always be 0.
  """
  @impl true
  def handle_cast({:add_broadcast, broadcast_time}, %{time_unit: target_unit} = state) do
    last_time = Map.get(state, :last_broadcast_time, broadcast_time)

    state = Map.put(state, :last_broadcast_time, broadcast_time)

    time_diff = broadcast_time - last_time

    Telemetry.execute(@telemetry_prefix, %{broadcast_time: time_diff}, %{})

    time_diff = Erlang.convert_time_unit(time_diff, :native, target_unit)

    updated_state = Map.update!(state, :broadcast_times, fn times -> [time_diff | times] end)

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:reset}, state) do
    {:noreply, get_initial_state(Map.fetch!(state, :time_unit))}
  end

  @impl true
  def handle_call({:get_gameloop}, _from, state) do
    {:reply, Map.get(state, :gameloop_times), state}
  end

  @impl true
  def handle_call({:get_gameloop_count}, _from, state) do
    {:reply, Map.get(state, :gameloop_count), state}
  end

  @impl true
  def handle_call({:get_broadcast}, _from, state) do
    {:reply, Map.get(state, :broadcast_times), state}
  end

  defp get_initial_state(time_unit) do
    %{gameloop_times: [], gameloop_count: 0, time_unit: time_unit, broadcast_times: []}
  end
end
