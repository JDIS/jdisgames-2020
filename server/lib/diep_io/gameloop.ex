defmodule Diep.Io.Gameloop do
  @moduledoc """
  Module that handles the time constraint of the server.
  It is responsible for generating iterations.
  """

  use GenServer
  alias Diep.Io.Core.GameState
  alias Diep.Io.UsersRepository
  require Logger

  # Client

  @spec start_link() :: {:ok, pid()}
  def start_link(_ \\ nil) do
    GenServer.start(__MODULE__, [], name: __MODULE__)
  end

  @spec start_game() :: :ok
  def start_game do
    Logger.info("Starting game")
    GenServer.cast(__MODULE__, :start_game)
  end

  @spec get_state() :: GameState.t()
  def get_state do
    GenServer.call(__MODULE__, :state)
  end

  # Server (callbacks)

  @impl true
  def init([]) do
    users = UsersRepository.list_users()
    Logger.info("Initializing gameloop with #{length(users)} users")
    {:ok, GameState.new(users)}
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
