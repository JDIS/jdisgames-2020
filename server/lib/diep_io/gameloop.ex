defmodule Diep.Io.Gameloop do
  @moduledoc false

  alias Diep.Io.Core.GameState

  use GenServer

  # Client

  @spec start_link([String.t()]) :: {:ok, pid()}
  def start_link(tank_names) do
    GenServer.start(__MODULE__, [tank_names], name: __MODULE__)
  end

  @spec start_game() :: :ok
  def start_game do
    GenServer.cast(__MODULE__, :start_game)
  end

  @spec get_state() :: GameState.t()
  def get_state do
    GenServer.call(__MODULE__, :state)
  end

  # Server (callbacks)

  @impl true
  def init([tank_names]) do
    {:ok, GameState.new(tank_names)}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:start_game, %{:in_progress => false} = state) do
    send(self(), :loop)
    {:noreply, GameState.start_game(state)}
  end

  @impl true
  def handle_cast(:start_game, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:loop, state) do
    Process.send_after(self(), :loop, 1000)
    {:noreply, state}
  end
end
