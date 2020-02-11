defmodule Diep.Io.Users.User do
  @moduledoc """
    A user controls a bot that participates in games.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          secret_key: String.t()
        }

  schema "users" do
    field :name, :string
    field :secret_key, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :secret_key])
    |> validate_required([:name, :secret_key])
  end
end
