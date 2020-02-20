defmodule Diep.Io.Core.GameState do
  @moduledoc """
  Module that handles most of the game's business logic
  (handle player actions, debris generation, etc).
  """

  alias Diep.Io.Core.{Action, Debris, GameMap, Position, Tank}
  alias Diep.Io.Users.User
  alias :rand, as: Rand

  @max_debris_count 100
  @max_debris_generation_rate 0.5
  @debris_size_probability [:small, :small, :small, :medium, :medium, :large]

  @derive {Jason.Encoder, except: [:in_progress, :last_time]}
  defstruct [
    :in_progress,
    :tanks,
    :debris,
    :last_time,
    :map_width,
    :map_height,
    :ticks,
    :max_ticks
  ]

  @type t :: %__MODULE__{
          in_progress: boolean(),
          tanks: %{integer() => Tank.t()},
          debris: [Debris.t()],
          last_time: integer(),
          map_width: integer(),
          map_height: integer(),
          ticks: integer(),
          max_ticks: integer()
        }

  @spec new([User.t()], integer()) :: t()
  def new(users, max_ticks) do
    %__MODULE__{
      in_progress: false,
      tanks: initialize_tanks(users),
      debris: initialize_debris(),
      last_time: 0,
      map_width: GameMap.width(),
      map_height: GameMap.height(),
      ticks: 1,
      max_ticks: max_ticks
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game_state), do: %{game_state | in_progress: true}

  @spec stop_game(t()) :: t()
  def stop_game(game_state), do: %{game_state | in_progress: false}

  @doc """
    Increase the tick count by one. If the new count is equal to the max number of ticks
    in a game, also stop the game.
  """
  @spec increase_ticks(t()) :: t()
  def increase_ticks(game_state) do
    updated_state = Map.put(game_state, :ticks, game_state.ticks + 1)
    max_ticks = updated_state.max_ticks

    case updated_state.ticks do
      x when x > max_ticks -> stop_game(updated_state)
      _ -> updated_state
    end
  end

  @spec handle_players([Action.t()], t()) :: t()
  def handle_players(actions, game_state) do
    Enum.reduce(actions, game_state, &handle_action/2)
  end

  @spec handle_debris(t()) :: t()
  def handle_debris(game_state) do
    game_state
    |> generate_debris
  end

  defp handle_action(action, game_state) do
    game_state
    |> handle_movement(action)
  end

  defp handle_movement(game_state, %Action{destination: destination}) when destination == nil,
    do: game_state

  defp handle_movement(game_state, action) do
    Map.update!(game_state, :tanks, fn tanks ->
      Map.update!(tanks, action.tank_id, fn tank ->
        new_position = Position.new(tank.position, action.destination, tank.speed)
        Tank.move(tank, new_position)
      end)
    end)
  end

  defp generate_debris(game_state) do
    case @max_debris_count - Enum.count(game_state.debris) do
      0 ->
        game_state

      missing_count ->
        rate = Rand.uniform() * @max_debris_generation_rate
        debris_count = max(round(missing_count * rate), 1)
        new_debris = create_debris(debris_count)
        %{game_state | debris: Enum.concat(game_state.debris, new_debris)}
    end
  end

  defp create_debris(count) do
    for _ <- 1..count, do: Debris.new(Enum.random(@debris_size_probability))
  end

  defp initialize_tanks(users),
    do: users |> Map.new(fn user -> {user.id, Tank.new(user.name)} end)

  defp initialize_debris, do: create_debris(@max_debris_count)
end
