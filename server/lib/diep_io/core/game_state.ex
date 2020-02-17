defmodule Diep.Io.Core.GameState do
  @moduledoc """
  Module that handles most of the game's business logic
  (handle player actions, debris generation, etc).
  """

  alias Diep.Io.Core.{Action, Position, Tank}
  alias Diep.Io.Users.User

  @derive {Jason.Encoder, except: [:in_progress]}
  defstruct [:in_progress, :tanks, :last_time, :map_width, :map_height]

  @type t :: %__MODULE__{
          in_progress: boolean(),
          tanks: %{integer() => Tank.t()},
          last_time: integer(),
          map_width: integer(),
          map_height: integer()
        }

  @spec new([User.t()]) :: t()
  def new(users) do
    %__MODULE__{
      in_progress: false,
      tanks: initialize_tanks(users),
      last_time: 0,
      map_width: 10_000,
      map_height: 10_000
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game_state), do: %{game_state | in_progress: true}

  @spec stop_game(t()) :: t()
  def stop_game(game_state), do: %{game_state | in_progress: false}

  @spec handle_players([Action.t()], t()) :: t()
  def handle_players(actions, game_state) do
    Enum.reduce(actions, game_state, &handle_action/2)
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

  defp initialize_tanks(users),
    do: users |> Map.new(fn user -> {user.id, Tank.new(user.name)} end)
end
