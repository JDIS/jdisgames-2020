defmodule Diep.Io.Monitor do
  @moduledoc false

  use GenServer
  alias :math, as: Math

  def start_link(_) do
    GenServer.start(__MODULE__, [], name: __MODULE__)
  end

  @spec store_gameloop_time(integer()) :: :ok
  def store_gameloop_time(sleep_time), do: GenServer.cast(__MODULE__, {:add_gameloop, sleep_time})

  @spec get_gameloop_stats :: {float, float}
  def get_gameloop_stats() do
    times = GenServer.call(__MODULE__, {:get_gameloop})

    times_length = length(times)

    average = Enum.sum(times) / times_length

    std_dev =
      times
      |> Enum.map(&Kernel.-(&1, average))
      |> Enum.map(&Math.pow(&1, 2))
      |> Enum.sum()
      |> Kernel./(times_length)
      |> Math.sqrt()

    {average, std_dev}
  end

  @spec get_gameloop_times :: [integer()]
  def get_gameloop_times(), do: GenServer.call(__MODULE__, {:get_gameloop})

  # Server callbacks

  @impl true
  def init(_) do
    {:ok, %{gameloop_times: []}}
  end

  @impl true
  def handle_cast({:add_gameloop, sleep_time}, state) do
    {:noreply, Map.update!(state, :gameloop_times, fn times -> [sleep_time | times] end)}
  end

  @impl true
  def handle_call({:get_gameloop}, _from, state) do
    {:reply, Map.get(state, :gameloop_times), state}
  end
end
