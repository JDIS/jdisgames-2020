defmodule DiepIOSchemas.GlobalParams do
  @moduledoc false

  use Ecto.Schema

  @type t :: %__MODULE__{
          enable_scoreboard_auth: boolean()
        }

  @primary_key false

  schema "global_params" do
    field(:enable_scoreboard_auth, :boolean)
  end
end
