defmodule DiepIOSchemas.User do
  @moduledoc """
    A user controls a bot that participates in games.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          name: String.t(),
          secret_key: String.t()
        }

  schema "users" do
    field(:name, :string)
    field(:secret_key, :string)

    timestamps()
  end
end
