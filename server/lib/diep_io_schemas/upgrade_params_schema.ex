defmodule DiepIOSchemas.UpgradeParamsSchema do
  use Ecto.Schema

  @type t :: %__MODULE__{
          upgrade_rate: float(),
          base_value: number()
        }

  @primary_key false

  schema "upgrade_params" do
    field :upgrade_rate, :float
    field :base_value, :float
  end
end
