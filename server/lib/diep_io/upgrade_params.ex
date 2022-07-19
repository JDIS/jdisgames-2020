defmodule DiepIO.UpgradeParams do
  @moduledoc false

  @type t :: %__MODULE__{
          upgrade_rate: float(),
          base_value: number()
        }

  @derive Jason.Encoder
  @enforce_keys [:upgrade_rate, :base_value]
  defstruct [:upgrade_rate, :base_value]
end
