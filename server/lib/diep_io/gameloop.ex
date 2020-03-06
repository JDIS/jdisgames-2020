defmodule Diep.Io.Gameloop do
  @moduledoc """
  Module that handles the time constraint of the server.
  It is responsible for generating iterations.
  """

  use GenServer
  alias Diep.IoWeb.Endpoint
  alias Diep.Io.Core.{Action, GameState}
  alias Diep.Io.{ActionStorage, UsersRepository}
  alias :erlang, as: Erlang
  require Logger

  @tickrate floor(1000 / 3)

  # Client

  @doc """
    Game_time is the number of ticks the game will last.
  """
  @spec start_link([integer()]) :: {:ok, pid()}
  def start_link([game_time]) do
    GenServer.start(__MODULE__, [game_time], name: __MODULE__)
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
  def init([game_time]) do
    users = UsersRepository.list_users()
    # Initialize ActionStorage's content with empty actions for each user
    users |> Enum.each(fn user -> ActionStorage.store_action(Action.new(user.id)) end)

    Logger.info("Initializing gameloop with #{length(users)} users")
    {:ok, GameState.new(users, game_time)}
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
  def handle_info(:loop, %{in_progress: true} = state) do
    begin_time = Erlang.monotonic_time()
    Logger.debug("looperoo took #{abs((state.last_time - begin_time) / 1_000_000)}ms")

    updated_state =
      state.tanks
      |> Map.keys()
      |> Enum.map(fn id -> ActionStorage.get_action(id) end)
      |> GameState.handle_players(state)
      |> GameState.handle_projectiles()
      |> GameState.handle_debris()
      |> GameState.increase_ticks()

    broadcast(updated_state)

    end_time = Erlang.monotonic_time()

    case updated_state.in_progress do
      true ->
        Process.send_after(self(), :loop, calculate_time_to_wait(end_time - begin_time))

      _ ->
        Logger.info("Stopping game. #{inspect(updated_state)}")
    end

    {:noreply, Map.put(updated_state, :last_time, end_time)}
  end

  defp calculate_time_to_wait(elapsed_time) do
    max(@tickrate - Erlang.convert_time_unit(elapsed_time, :native, :millisecond), 0)
  end

  defp broadcast(state) do
    Endpoint.broadcast!("game_state", "new_state", state)
  end
end
