defmodule Diep.Io.Gameloop do
  @moduledoc false

  alias Diep.Io.Core.Tank

  use GenServer

  @type gameloop_state() :: %{
          in_progress: boolean(),
          tanks: [Tank.t()]
        }

  @default_state %{
    in_progress: false,
    tanks: []
  }

  # Client

  @spec start_link([String.t()]) :: {:ok, pid()}
  def start_link(tank_names) do
    GenServer.start(__MODULE__, [tank_names], name: __MODULE__)
  end

  @spec start_game() :: :ok
  def start_game do
    GenServer.cast(__MODULE__, :start_game)
  end

  @spec get_state() :: gameloop_state()
  def get_state do
    GenServer.call(__MODULE__, :state)
  end

  # Server (callbacks)

  @impl true
  def init([tank_names]) do
    {:ok, initialize_state(tank_names)}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:start_game, %{:in_progress => false} = state) do
    send(self(), :loop)
    {:noreply, %{state | :in_progress => true}}
  end

  @impl true
  def handle_cast(:start_game, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:loop, state) do
    IO.puts("loop")
    Process.send_after(self(), :loop, 1000)
    {:noreply, state}
  end

  # Private functions

  defp initialize_state(tank_names) do
    @default_state
    |> initialize_tanks(tank_names)
  end

  defp initialize_tanks(state, tank_names) do
    tanks =
      tank_names
      |> Enum.map(&Tank.new/1)

    %{state | tanks: tanks}
  end
end
