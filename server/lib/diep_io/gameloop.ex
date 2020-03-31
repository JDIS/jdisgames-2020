defmodule Diep.Io.Gameloop do
  @moduledoc """
  Module that handles the time constraint of the server.
  It is responsible for generating iterations.
  """

  use GenServer
  alias Diep.Io.{ActionStorage, ScoreRepository, UsersRepository}
  alias Diep.IoWeb.Endpoint
  alias Diep.Io.Core.{Action, GameState}
  alias :erlang, as: Erlang
  require Logger

  @tickrate floor(1000 / 3)

  # Client

  @doc """
    Game_time is the number of ticks the game will last.
  """
  @spec start_link(name: atom(), game_time: integer(), persistent?: boolean()) :: {:ok, pid()}
  def start_link(name: name, game_time: game_time, persistent?: persistent?) do
    GenServer.start(__MODULE__, [name: name, game_time: game_time, persistent?: persistent?], name: name)
  end

  @spec stop_game(atom()) :: :ok
  def stop_game(name), do: GenServer.stop(name)

  # Server (callbacks)
  @impl true
  def init(name: name, game_time: game_time, persistent?: persistent?) do
    :ok = ActionStorage.init(name)
    init_game_state(name, game_time, persistent?)
  end

  @impl true
  def handle_info(:reset_game, state) do
    :ok = save_scores(state)
    :ok = ActionStorage.reset(state.name)
    {:ok, new_state} = init_game_state(state.name, state.max_ticks, state.persistent?)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:loop, state) do
    begin_time = Erlang.monotonic_time()
    Logger.debug("looperoo took #{abs((state.last_time - begin_time) / 1_000_000)}ms")

    updated_state =
      state.tanks
      |> Map.keys()
      |> Enum.map(fn id -> ActionStorage.get_action(state.name, id) end)
      |> GameState.handle_players(state)
      |> GameState.handle_projectiles()
      |> GameState.handle_debris()
      |> GameState.handle_collisions()
      |> GameState.decrease_cooldowns()
      |> GameState.increase_ticks()

    broadcast(updated_state)

    end_time = Erlang.monotonic_time()

    case GameState.in_progress?(updated_state) do
      true ->
        Process.send_after(self(), :loop, calculate_time_to_wait(end_time - begin_time))

      false ->
        send(self(), :reset_game)
    end

    {:noreply, Map.put(updated_state, :last_time, end_time)}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Gameloop #{inspect(self())} terminating because #{inspect(reason)}")

    if reason == :normal do
      :ok = save_scores(state)
    end
  end

  # Privates
  defp init_game_state(name, game_time, persistent?) do
    game_id = System.unique_integer()
    users = UsersRepository.list_users()
    # Initialize ActionStorage's content with empty actions for each user
    users |> Enum.each(fn user -> ActionStorage.store_action(name, Action.new(user.id)) end)

    Logger.info("Initialized gameloop #{game_id} with #{length(users)} users")
    send(self(), :loop)
    {:ok, GameState.new(name, users, game_time, game_id, persistent?)}
  end

  defp calculate_time_to_wait(elapsed_time) do
    max(@tickrate - Erlang.convert_time_unit(elapsed_time, :native, :millisecond), 0)
  end

  defp broadcast(state) do
    Endpoint.broadcast!("game_state", "new_state", state)
  end

  defp save_scores(%{persistent?: true} = state) do
    scores =
      Enum.map(state.tanks, fn {tank_id, tank} ->
        %{user_id: tank_id, score: tank.score, game_id: state.game_id}
      end)

    Enum.each(scores, fn score -> ScoreRepository.add_score(score) end)

    :ok
  end

  defp save_scores(_state), do: :ok
end
